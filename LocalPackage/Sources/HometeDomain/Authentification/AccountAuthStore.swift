//
//  AccountAuthStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import Observation

@MainActor
@Observable
public final class AccountAuthStore {

    public private(set) var currentAuth: AccountAuthInfo

    private let accountAuthClient: AccountAuthClient
    private let analyticsClient: AnalyticsClient
    private let signInWithAppleClient: SignInWithAppleClient
    private let nonceGenerationClient: NonceGenerationClient
    private let listener: AccountListenerStream

    public init(
        accountAuthClient: AccountAuthClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        signInWithAppleClient: SignInWithAppleClient = .previewValue,
        nonceGenerationClient: NonceGenerationClient = .previewValue,
        currentAuth: AccountAuthInfo = .initial
    ) {
        self.accountAuthClient = accountAuthClient
        self.analyticsClient = analyticsClient
        self.signInWithAppleClient = signInWithAppleClient
        self.nonceGenerationClient = nonceGenerationClient
        self.currentAuth = currentAuth

        listener = accountAuthClient.makeListener()

        Task {
            await listen()
        }
    }

    public func login(_ signInResult: SignInWithAppleResult) async throws {
        do {
            let authInfo = try await accountAuthClient.signIn(signInResult.tokenId, signInResult.nonce)
            analyticsClient.setId(authInfo.id)
            analyticsClient.log(.login(isSuccess: true))
        } catch {
            analyticsClient.log(.login(isSuccess: false))
            throw error
        }
    }

    /// 匿名認証で始める
    /// - Note: サインインした結果は、認証状態のリスナーから`currentAuth`に届く
    public func startAnonymously() async throws {
        do {
            let authInfo = try await accountAuthClient.signInAnonymously()
            analyticsClient.setId(authInfo.id)
            analyticsClient.log(.login(isSuccess: true, method: .anonymous))
        } catch {
            analyticsClient.log(.login(isSuccess: false, method: .anonymous))
            throw error
        }
    }

    /// 匿名のアカウントをAppleアカウントと連携する
    /// - Throws: すでに別のアカウントで使われているAppleアカウントなら`AccountLinkError.credentialAlreadyInUse`。
    ///           受け取った認証情報は`switchToExistingAccount(_:)`に渡す
    public func linkWithApple(_ signInResult: SignInWithAppleResult) async throws {
        let linkedAuth = try await accountAuthClient.linkWithApple(signInResult.tokenId, signInResult.nonce)
        // 連携してもuidは変わらないため、認証状態のリスナーは呼ばれない。匿名でなくなったことをここで反映する
        currentAuth = .init(result: linkedAuth, alreadyLoadedAtInitiate: true)
    }

    /// 匿名のアカウントを削除して、連携しようとしたAppleアカウントで使っていたアカウントへ切り替える
    /// - Note: 匿名で登録した内容は引き継がない
    public func switchToExistingAccount(_ credential: ExistingAccountCredential) async throws {
        try await accountAuthClient.deleteAnonymousAccount()
        // サインアウトを挟まずにユーザーが替わるため、新しいIDで送るログインのイベントに、削除した匿名のアカウントの
        // ユーザープロパティが載ってしまう。先に消し、切り替え先の値はログイン状態が決まった時点で設定し直してもらう
        analyticsClient.setUserProperty(.cleared(.hasCohabitant))
        analyticsClient.setUserProperty(.cleared(.cohabitantMemberCount))
        analyticsClient.setUserProperty(.cleared(.isAnonymous))

        do {
            let authInfo = try await accountAuthClient.signInWithExistingCredential(credential)
            analyticsClient.setId(authInfo.id)
            analyticsClient.log(.login(isSuccess: true))
        } catch {
            analyticsClient.log(.login(isSuccess: false))
            // 匿名のアカウントはもう無いため、サインアウトしてログイン画面からやり直してもらう
            signOut()
            throw error
        }
    }

    public func logOut() {
        signOut()
        analyticsClient.log(.logout())
    }

    public func deleteAccount() async throws {
        if currentAuth.result?.isAnonymous == true {
            try await deleteAnonymousAccount()
            return
        }

        // 1. 再認証
        let nonce = nonceGenerationClient()
        let signInWithAppleResult = try await signInWithAppleClient.reauthentication(nonce)
        try await accountAuthClient.reauthenticateWithApple(signInWithAppleResult)

        // 2. アカウント削除
        try await accountAuthClient.deleteAccount()

        // 3. トークンRevoke
        try await accountAuthClient.revokeAppleToken(signInWithAppleResult.authorizationCode)

        // 4. ログ記録
        analyticsClient.log(.deleteAccount())

        // 5. 状態更新
        currentAuth = .init(result: nil, alreadyLoadedAtInitiate: true)
    }

}

private extension AccountAuthStore {

    func signOut() {
        currentAuth = .init(result: nil, alreadyLoadedAtInitiate: true)

        do {
            try accountAuthClient.signOut()
        } catch {
            print("occurred error: \(error)")
        }
    }

    /// 匿名のアカウントは再認証の手段が無く、Appleのトークンも持たないため、削除だけ行う
    func deleteAnonymousAccount() async throws {
        try await accountAuthClient.deleteAnonymousAccount()
        analyticsClient.log(.deleteAccount())
        // サーバー側で削除しても、端末にはサインインした状態が残るためサインアウトする
        signOut()
    }

    func listen() async {
        for await value in listener.values {
            currentAuth = .init(result: value, alreadyLoadedAtInitiate: true)
            print("currentAuth snapshot: \(String(describing: currentAuth))")
        }
    }

}
