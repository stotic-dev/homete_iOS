//
//  AccountStoreTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import Testing
@testable import homete

@MainActor
struct AccountStoreTest {

    @Test("ログイン時にサーバーにアカウント情報を登録する")
    func test_setAccountOnLogin() async throws {
        
        await confirmation(expectedCount: 2) { confirmation in
            
            let inputAuthResult = AccountAuthResult(id: "test", displayName: "testName")
            let accountInfoClient = AccountInfoClient {
                
                confirmation()
                let expectedAccount = try Account(id: inputAuthResult.id, displayName: #require(inputAuthResult.displayName))
                #expect($0 == expectedAccount)
            } fetch: {
                
                confirmation()
                #expect($0 == inputAuthResult.id)
                return nil
            }
            let store = AccountStore(appDependencies: .init(accountInfoClient: accountInfoClient))
            
            await store.setAccountOnLogin(inputAuthResult)
        }
    }

}
