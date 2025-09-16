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

    @Test("初回ログインでサーバーにアカウント情報がない場合、サーバーにアカウント情報を登録する")
    func loadOwnAccountData() async throws {
        
        await confirmation(expectedCount: 2) { confirmation in
            
            let inputAuthResult = AccountAuthResult(id: "test", displayName: "testName")
            let accountInfoClient = AccountInfoClient {
                
                confirmation()
                let expectedAccount = try Account(
                    id: inputAuthResult.id,
                    displayName: #require(inputAuthResult.displayName, ""),
                    fcmToken: nil
                )
                #expect($0 == expectedAccount)
            } fetch: {
                
                confirmation()
                #expect($0 == inputAuthResult.id)
                return nil
            }
            let store = AccountStore(appDependencies: .init(accountInfoClient: accountInfoClient))
            
            await store.loadOwnAccountData(inputAuthResult, fcmToken: nil)
        }
    }
    
    @Test("サーバーにログイン情報がありFCMトークンが更新されている場合アカウントに紐づくFCMトークンを更新")
    func updateFcmTokenIfNeeded() async {
        
        await confirmation(expectedCount: 2) { confirmation in
            
            let inputFcmToken = "token"
            let inputAuthResult = AccountAuthResult(id: "test", displayName: "testName")
            let accountInfoClient = AccountInfoClient {
                
                confirmation()
                let expectedAccount = try Account(
                    id: inputAuthResult.id,
                    displayName: #require(inputAuthResult.displayName, ""),
                    fcmToken: inputFcmToken
                )
                #expect($0 == expectedAccount)
            } fetch: {
                
                confirmation()
                #expect($0 == inputAuthResult.id)
                return try Account(
                    id: inputAuthResult.id,
                    displayName: #require(inputAuthResult.displayName, ""),
                    fcmToken: nil
                )
            }
            let store = AccountStore(appDependencies: .init(accountInfoClient: accountInfoClient))
            
            await store.loadOwnAccountData(inputAuthResult, fcmToken: inputFcmToken)
        }
    }
}
