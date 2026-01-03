//
//  AccountAuthStoreTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import os
import Testing
@testable import homete

@MainActor
struct AccountAuthStoreTest {

    @Test("ログイン処理ではサーバー側でサインイン後、成功したらログを送信する")
    func test_login() async throws {
        
        let inputTokenId = "testId"
        let inputNonce = "testNonce"
        let outputAccount = AccountAuthResult(id: "testAccountId")
        
        try await confirmation(expectedCount: 4) { confirmation in
            
            let store = AccountAuthStore(appDependencies: .init(
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
            ))
            
            try await store.login(.init(tokenId: inputTokenId, nonce: inputNonce, authorizationCode: "code"))
        }
    }
    
    @Test("ログアウト時はローカルのログイン状態をログアウトにしてログアウト処理を行い、イベントログを送信する")
    func test_logout() throws {
        
        let isCallSignOut = OSAllocatedUnfairLock(initialState: false)
        let isCallAnalyticsLog = OSAllocatedUnfairLock(initialState: false)
        
        let store = AccountAuthStore(
            appDependencies: .init(
                accountAuthClient: .init(
                    signIn: { _, _ in
                        
                        Issue.record()
                        return .init(id: "")
                    },
                    signOut: { isCallSignOut.withLock { $0 = true } },
                    makeListener: { .defaultValue() }
                ),
                analyticsClient: .init(
                    setId: { _ in
                        
                        Issue.record()
                    },
                    log: { event in
                        
                        isCallAnalyticsLog.withLock { $0 = true }
                        #expect(event == .logout())
                    }
                )
            ),
            currentAuth: .init(result: .init(id: "test"), alreadyLoadedAtInitiate: true)
        )
            
        store.logOut()
        
        #expect(isCallSignOut.withLock { $0 })
        #expect(isCallAnalyticsLog.withLock { $0 })
        #expect(store.currentAuth == .init(result: nil, alreadyLoadedAtInitiate: true))
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
                appDependencies: .init(
                    nonceGeneratorClient: .init {
                        
                        confirmation()
                        return inputNonce
                    },
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
                        },
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
                    }
                ),
                currentAuth: .init(result: .init(id: "test"), alreadyLoadedAtInitiate: true)
            )
            
            // Act
            try await store.deleteAccount()
            
            // Assert
            #expect(store.currentAuth == .init(result: nil, alreadyLoadedAtInitiate: true))
        }
    }
}
