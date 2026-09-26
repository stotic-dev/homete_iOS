//
//  AccountStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import Observation

@MainActor
@Observable
public final class AccountStore {

    public private(set) var account: Account?
    private var listenerTask: Task<Void, Never>?

    private let accountListenerKey = "accountListenerKey"
    private let accountInfoClient: AccountInfoClient

    public init(
        accountInfoClient: AccountInfoClient = .previewValue,
        account: Account? = nil
    ) {
        self.accountInfoClient = accountInfoClient
        self.account = account
    }

    /// アカウント情報をロードし、オンメモリにキャッシュする
    /// - Returns: ロードしたアカウント情報を返す（アカウントがない場合はnilを返す）
    @discardableResult
    public func load(_ auth: AccountAuthResult) async -> Account? {
        do {
            account = try await accountInfoClient.fetch(auth.id)
        } catch {
            print("failed to fetch account info: \(error)")
        }

        return account
    }

    /// Firestore上のアカウント情報を取り直し、オンメモリのキャッシュを更新する
    /// - Note: ログイン後にサーバ側でアカウントが消えているケースを、
    ///         後続の処理が`preconditionFailure`で落ちる前に検知するために使う
    /// - Throws: アカウントを保持していない、またはFirestoreにアカウントが無い場合は`DomainError.accountNotFound`
    public func reload() async throws {
        guard let account else { throw DomainError.accountNotFound }
        guard let fetchedAccount = try await accountInfoClient.fetch(account.id) else {
            throw DomainError.accountNotFound
        }
        self.account = fetchedAccount
    }

    public func registerAccount(auth: AccountAuthResult, userName: UserName) async throws -> Account {
        let newAccount = Account(id: auth.id, userName: userName.value, fcmToken: nil, cohabitantId: nil)
        try await accountInfoClient.insertOrUpdate(newAccount)
        account = newAccount
        return newAccount
    }

    public func updateFcmTokenIfNeeded(_ fcmToken: String) async {
        // 保持しているFCMトークンと異なるFCMトークンに変わった場合は、アカウント情報も新しいトークンに更新する
        guard let account,
              account.fcmToken != fcmToken else { return }

        do {
            let updatedAccount = Account(
                id: account.id,
                userName: account.userName,
                fcmToken: fcmToken,
                cohabitantId: account.cohabitantId,
                isPremium: account.isPremium
            )
            try await accountInfoClient.insertOrUpdate(updatedAccount)
            self.account = updatedAccount
        } catch {
            print("failed to update fcmToken: \(error)")
        }
    }

    /// 自分のアカウントの購読を開始し、サーバー側で更新された内容をオンメモリに反映する
    /// - Note: 招待リンク経由で相手が参加すると、Cloud Functionsが発行者の`cohabitantId`を更新する。
    ///         クライアントからの書き込みではないため、購読していないと再起動するまでグループ未所属のままになる
    public func startObservingIfNeeded(_ accountId: String) async {
        // すでに購読中の場合は何もしない
        if listenerTask != nil { return }

        let stream = await accountInfoClient.addSnapshotListener(accountListenerKey, accountId)

        // 購読の準備中にサインアウトが起きた場合、`stopObserving()`は`listenerTask`が未設定なので
        // 空振りする。そのまま購読を張ると解除されないまま残るため、ここで畳む
        guard !Task.isCancelled else {
            await accountInfoClient.removeSnapshotListener(accountListenerKey)
            return
        }

        listenerTask = Task {
            do {
                for try await account in stream {
                    // 削除（退会）の通知はサインアウト側の処理に任せ、ここではnilで上書きしない
                    guard let account else { continue }
                    self.account = account
                }
            } catch {
                // 購読を継続できなくなった場合は、再度購読できるようにタスクを解放する
                print("error occurred at account snapshot listener: \(error)")
                listenerTask = nil
            }
        }
    }

    /// 自分のアカウントの購読を停止する
    public func stopObserving() async {
        listenerTask?.cancel()
        await listenerTask?.value
        listenerTask = nil
        await accountInfoClient.removeSnapshotListener(accountListenerKey)
    }

    /// 保持しているアカウント情報をクリアする
    public func clear() {
        account = nil
    }

    public func registerCohabitantId(_ cohabitantId: String) async throws {
        guard let account else {
            preconditionFailure("Not found account.")
        }

        let updatedAccount = Account(
            id: account.id,
            userName: account.userName,
            fcmToken: account.fcmToken,
            cohabitantId: cohabitantId,
            isPremium: account.isPremium
        )
        try await accountInfoClient.insertOrUpdate(updatedAccount)
        self.account = updatedAccount
    }

    /// 保持しているアカウント情報のグループIDのみを差し替える
    /// - Note: サーバ側（Cloud Functions）でアカウントを更新済みのケース用。
    ///         Firestoreへは書き込まず、オンメモリの状態だけを同期する
    public func applyCohabitantId(_ cohabitantId: String) {
        guard let account,
              account.cohabitantId != cohabitantId else { return }

        self.account = Account(
            id: account.id,
            userName: account.userName,
            fcmToken: account.fcmToken,
            cohabitantId: cohabitantId,
            isPremium: account.isPremium
        )
    }

    /// プレミアム加入状態が変わっている場合のみアカウント情報を更新する
    /// - Returns: 更新が発生したかどうか
    @discardableResult
    public func updateIsPremiumIfNeeded(_ isPremium: Bool) async -> Bool {
        guard let account,
              account.isPremium != isPremium else { return false }

        do {
            let updatedAccount = account.updateIsPremium(isPremium)
            try await accountInfoClient.insertOrUpdate(updatedAccount)
            self.account = updatedAccount
            return true
        } catch {
            print("failed to update isPremium: \(error)")
            return false
        }
    }

}
