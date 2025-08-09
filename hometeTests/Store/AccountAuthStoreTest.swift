//
//  AccountAuthStoreTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import Testing
@testable import homete

@MainActor
struct AccountAuthStoreTest {

    @Test("ログイン処理ではサーバー側でサインイン後、成功したらログを送信する")
    func test_login() async throws {
        
        let inputTokenId = "testId"
        let inputNonce = "testNonce"
        let outputAccount = AccountAuthResult(id: "testAccountId", displayName: "testDisplayName")
        
        try await confirmation(expectedCount: 4) { confirmation in
            
            let store = AccountAuthStore(appDependencies: .init(
                accountAuthClient: .init(signIn: { tokenId, nonce in
                    
                    confirmation()
                    #expect(tokenId == inputTokenId)
                    #expect(nonce == inputNonce)
                    return outputAccount
                },
                                     signOut: { confirmation() },
                                     makeListener: {
                                         
                                         confirmation()
                                         return .defaultValue()
                                     }),
                analyticsClient: .init(setId: { id in
                    
                    confirmation()
                    #expect(id == outputAccount.id)
                }, log: { event in
                    
                    confirmation()
                    #expect(event == .login(isSuccess: true))
                })
            ))
            
            try await store.login(.init(tokenId: inputTokenId, nonce: inputNonce))
        }
    }
}
