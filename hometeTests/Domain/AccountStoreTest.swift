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

    @Test("アカウント情報をロードし、アカウントがある場合はアカウント情報を返す")
    func load() async throws {
        
        // Arrange
        let inputAccountId = "test"
        let inputAccount = Account(
            id: inputAccountId,
            userName: "testUserName",
            fcmToken: "testToken",
            cohabitantId: nil
        )
        
        await confirmation(expectedCount: 1) { confirmation in
            
            let inputAuthResult = AccountAuthResult(id: "test")
            let accountInfoClient = AccountInfoClient(fetch: {
                
                confirmation()
                #expect($0 == inputAuthResult.id)
                return inputAccount
            })
            let store = AccountStore(appDependencies: .init(accountInfoClient: accountInfoClient))
            
            // Act
            let actual = await store.load(inputAuthResult)
            
            // Assert
            #expect(actual == inputAccount)
        }
    }
    
    @Test("サーバーにログイン情報がありFCMトークンが更新されている場合アカウントに紐づくFCMトークンを更新")
    func updateFcmTokenIfNeeded() async {
        
        await confirmation(expectedCount: 1) { confirmation in
            
            // Arrange
            let inputFcmToken = "token"
            let initialAccount = Account(id: "testId", userName: "testUser", fcmToken: nil, cohabitantId: nil)
            let expectedAccount = Account(
                id: initialAccount.id,
                userName: initialAccount.userName,
                fcmToken: inputFcmToken,
                cohabitantId: nil
            )
            let accountInfoClient = AccountInfoClient(insertOrUpdate: {
                
                confirmation()
                #expect($0 == expectedAccount)
            })
            let store = AccountStore(
                appDependencies: .init(accountInfoClient: accountInfoClient),
                account: initialAccount
            )
            
            // Act
            await store.updateFcmTokenIfNeeded(inputFcmToken)
            
            // Assert
            #expect(store.account == expectedAccount)
        }
    }
    
    @Test("パートナーの登録で保持しているアカウントにパートナーグループIDの情報を更新する")
    func registerCohabitantId() async throws {
        
        try await confirmation(expectedCount: 1) { confirmation in
            
            // Arrange
            let inputCohabitantId = "testCohabitantId"
            let initialAccount = Account(
                id: "testId",
                userName: "testUser",
                fcmToken: nil,
                cohabitantId: nil
            )
            let expectedAccount = Account(
                id: initialAccount.id,
                userName: initialAccount.userName,
                fcmToken: nil,
                cohabitantId: inputCohabitantId
            )
            let accountInfoClient = AccountInfoClient(insertOrUpdate: {
                
                confirmation()
                #expect($0 == expectedAccount)
            })
            let store = AccountStore(
                appDependencies: .init(accountInfoClient: accountInfoClient),
                account: initialAccount
            )
            
            // Act
            try await store.registerCohabitantId(inputCohabitantId)
            
            // Assert
            #expect(store.account == expectedAccount)
        }
    }
}
