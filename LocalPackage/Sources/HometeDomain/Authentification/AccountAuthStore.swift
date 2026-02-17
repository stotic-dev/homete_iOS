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
        }
        catch {

            analyticsClient.log(.login(isSuccess: false))
            throw error
        }
    }

    public func logOut() {

        currentAuth = .init(result: nil, alreadyLoadedAtInitiate: true)
        analyticsClient.log(.logout())

        do {

            try accountAuthClient.signOut()
        }
        catch {

            print("occurred error: \(error)")
        }
    }

    public func deleteAccount() async throws {

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

    func listen() async {

        for await value in listener.values {

            currentAuth = .init(result: value, alreadyLoadedAtInitiate: true)
            print("currentAuth snapshot: \(String(describing: currentAuth))")
        }
    }
}
