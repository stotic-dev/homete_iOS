//
//  AccountAuthStoreTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/08/09.
//

@testable import HometeDomain
import Testing

@MainActor
struct AccountAuthStoreTest {

    @Test("ログイン処理ではサーバー側でサインイン後、成功したらログを送信する")
    func test_login() async throws {
        let inputTokenId = "testId"
        let inputNonce = "testNonce"
        let outputAccount = AccountAuthResult(id: "testAccountId")

        try await confirmation(expectedCount: 4) { confirmation in
            let store = AccountAuthStore(
                accountAuthClient: .init(
                    signIn: { tokenId, nonce in
                        confirmation()
                        #expect(tokenId == inputTokenId)
                        #expect(nonce == inputNonce)
                        return outputAccount
                    },
                    signOut: { confirmation() },
                    makeListener: {
                        confirmation()
                        return .defaultValue()
                    }
                ),
                analyticsClient: .init(
                    setId: { id in
                        confirmation()
                        #expect(id == outputAccount.id)
                    }, log: { event in
                        confirmation()
                        #expect(event == .login(isSuccess: true))
                    }
                )
            )

            try await store.login(.init(tokenId: inputTokenId, nonce: inputNonce, authorizationCode: "code"))
        }
    }

    @Test("ログアウト時はローカルのログイン状態をログアウトにしてログアウト処理を行い、イベントログを送信する")
    func test_logout() async {
        await confirmation(expectedCount: 3) { confirmation in
            let store = AccountAuthStore(
                accountAuthClient: .init(
                    signIn: { _, _ in
                        Issue.record()
                        return .init(id: "")
                    },
                    signOut: { confirmation() },
                    makeListener: {
                        confirmation()
                        return .defaultValue()
                    }
                ),
                analyticsClient: .init(
                    setId: { _ in
                        Issue.record()
                    },
                    log: { event in
                        confirmation()
                        #expect(event == .logout())
                    }
                ),
                currentAuth: .init(result: .init(id: "test"), alreadyLoadedAtInitiate: true)
            )

            store.logOut()

            #expect(store.currentAuth == .init(result: nil, alreadyLoadedAtInitiate: true))
        }
    }

    @Test("再認証を行った後にアカウントを削除し認証トークンの無効化を行いログアウト状態にすることで、退会処理を完了させる")
    func deleteAccount() async throws {
        // Arrange
        let inputNonce = SignInWithAppleNonce(original: "originalTestNonce", sha256: "sha256TestNonce")
        let inputSignInWithAppleResult = SignInWithAppleResult(
            tokenId: "testToken",
            nonce: inputNonce.sha256,
            authorizationCode: "testCode"
        )

        try await confirmation(expectedCount: 6) { confirmation in
            let store = AccountAuthStore(
                accountAuthClient: .init(
                    reauthenticateWithApple: { result in
                        confirmation()
                        #expect(result == inputSignInWithAppleResult)
                    },
                    revokeAppleToken: { code in
                        confirmation()
                        #expect(code == inputSignInWithAppleResult.authorizationCode)
                    },
                    deleteAccount: {
                        confirmation()
                    }
                ),
                analyticsClient: .init(
                    log: { event in
                        confirmation()
                        #expect(event == .deleteAccount())
                    }
                ),
                signInWithAppleClient: .init { nonce in
                    confirmation()
                    #expect(nonce == inputNonce)
                    return inputSignInWithAppleResult
                },
                nonceGenerationClient: .init {
                    confirmation()
                    return inputNonce
                },
                currentAuth: .init(result: .init(id: "test"), alreadyLoadedAtInitiate: true)
            )

            // Act
            try await store.deleteAccount()

            // Assert
            #expect(store.currentAuth == .init(result: nil, alreadyLoadedAtInitiate: true))
        }
    }

    @Test("Appleアカウントと連携すると、匿名でなくなった認証状態に更新する")
    func linkWithApple() async throws {
        // Arrange
        let inputSignInWithAppleResult = SignInWithAppleResult(
            tokenId: "testToken",
            nonce: "testNonce",
            authorizationCode: "testCode"
        )
        let store = AccountAuthStore(
            accountAuthClient: .init(
                makeListener: { .defaultValue() },
                linkWithApple: { tokenId, nonce in
                    #expect(tokenId == inputSignInWithAppleResult.tokenId)
                    #expect(nonce == inputSignInWithAppleResult.nonce)
                    return .init(id: "anonymousId", isAnonymous: false)
                }
            ),
            currentAuth: .init(result: .init(id: "anonymousId", isAnonymous: true), alreadyLoadedAtInitiate: true)
        )

        // Act
        try await store.linkWithApple(inputSignInWithAppleResult)

        // Assert
        let expected = AccountAuthInfo(
            result: .init(id: "anonymousId", isAnonymous: false),
            alreadyLoadedAtInitiate: true
        )
        #expect(store.currentAuth == expected)
    }

    @Test("既存のアカウントへ切り替えるときは、匿名のアカウントを削除してから受け取った認証情報でログインする")
    func switchToExistingAccount() async throws {
        // Arrange
        let calledMethods = TestLockedArray<String>()
        let store = AccountAuthStore(
            accountAuthClient: .init(
                signOut: { Issue.record() },
                makeListener: { .defaultValue() },
                signInWithExistingCredential: { credential in
                    #expect(credential.rawValue as? String == "existingCredential")
                    await calledMethods.append("signInWithExistingCredential")
                    return .init(id: "existingId")
                },
                deleteAnonymousAccount: {
                    await calledMethods.append("deleteAnonymousAccount")
                }
            ),
            analyticsClient: .init(
                setId: { id in
                    #expect(id == "existingId")
                },
                log: { event in
                    #expect(event == .login(isSuccess: true))
                }
            ),
            currentAuth: .init(result: .init(id: "anonymousId", isAnonymous: true), alreadyLoadedAtInitiate: true)
        )

        // Act
        try await store.switchToExistingAccount(.init(rawValue: "existingCredential"))

        // Assert
        let actual = await calledMethods.values
        #expect(actual == ["deleteAnonymousAccount", "signInWithExistingCredential"])
    }

    @Test("既存のアカウントへのログインに失敗したら、匿名のアカウントは削除済みのためサインアウトする")
    func switchToExistingAccount_signInFailed() async {
        await confirmation(expectedCount: 2) { confirmation in
            // Arrange
            let store = AccountAuthStore(
                accountAuthClient: .init(
                    signOut: { confirmation() },
                    makeListener: { .defaultValue() },
                    signInWithExistingCredential: { _ in
                        throw DomainError.failAuth
                    }
                ),
                analyticsClient: .init(
                    log: { event in
                        confirmation()
                        #expect(event == .login(isSuccess: false))
                    }
                ),
                currentAuth: .init(result: .init(id: "anonymousId", isAnonymous: true), alreadyLoadedAtInitiate: true)
            )

            // Act
            await #expect(throws: DomainError.failAuth) {
                try await store.switchToExistingAccount(.init(rawValue: "existingCredential"))
            }

            // Assert
            #expect(store.currentAuth == .init(result: nil, alreadyLoadedAtInitiate: true))
        }
    }

    @Test("匿名のアカウントの退会は、再認証とトークンの無効化を行わずに削除してサインアウトする")
    func deleteAccount_anonymous() async throws {
        try await confirmation(expectedCount: 3) { confirmation in
            // Arrange
            let store = AccountAuthStore(
                accountAuthClient: .init(
                    signOut: { confirmation() },
                    makeListener: { .defaultValue() },
                    reauthenticateWithApple: { _ in Issue.record() },
                    revokeAppleToken: { _ in Issue.record() },
                    deleteAccount: { Issue.record() },
                    deleteAnonymousAccount: { confirmation() }
                ),
                analyticsClient: .init(
                    log: { event in
                        confirmation()
                        #expect(event == .deleteAccount())
                    }
                ),
                signInWithAppleClient: .init { _ in
                    Issue.record()
                    return .init(tokenId: "", nonce: "", authorizationCode: "")
                },
                currentAuth: .init(result: .init(id: "anonymousId", isAnonymous: true), alreadyLoadedAtInitiate: true)
            )

            // Act
            try await store.deleteAccount()

            // Assert
            #expect(store.currentAuth == .init(result: nil, alreadyLoadedAtInitiate: true))
        }
    }

}
