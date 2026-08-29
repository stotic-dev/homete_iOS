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
