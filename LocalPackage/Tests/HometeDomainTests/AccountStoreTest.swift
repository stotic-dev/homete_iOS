//
//  AccountStoreTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/08/09.
//

@testable import HometeDomain
import Testing

@MainActor
struct AccountStoreTest {

    @Test("アカウント情報をロードし、アカウントがある場合はアカウント情報を返す")
    func load() async {
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
            let store = AccountStore(accountInfoClient: accountInfoClient)

            // Act
            let actual = await store.load(inputAuthResult)

            // Assert
            #expect(actual == inputAccount)
        }
    }

    @Test("グループIDのみを差し替える場合、Firestoreへは書き込まずオンメモリの状態だけ更新する")
    func applyCohabitantId() {
        // Arrange
        let initialAccount = Account(id: "testId", userName: "testUser", fcmToken: "token", cohabitantId: nil)
        let expectedAccount = Account(
            id: "testId",
            userName: "testUser",
            fcmToken: "token",
            cohabitantId: "joinedCohabitantId"
        )
        let accountInfoClient = AccountInfoClient(insertOrUpdate: { _ in
            Issue.record()
        })
        let store = AccountStore(accountInfoClient: accountInfoClient, account: initialAccount)

        // Act
        store.applyCohabitantId("joinedCohabitantId")

        // Assert
        #expect(store.account == expectedAccount)
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
                accountInfoClient: accountInfoClient,
                account: initialAccount
            )

            // Act
            await store.updateFcmTokenIfNeeded(inputFcmToken)

            // Assert
            #expect(store.account == expectedAccount)
        }
    }

    @Test("保持しているアカウント情報をクリアする")
    func clear() {
        // Arrange
        let initialAccount = Account(id: "testId", userName: "testUser", fcmToken: nil, cohabitantId: nil)
        let store = AccountStore(account: initialAccount)

        // Act
        store.clear()

        // Assert
        #expect(store.account == nil)
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
                accountInfoClient: accountInfoClient,
                account: initialAccount
            )

            // Act
            try await store.registerCohabitantId(inputCohabitantId)

            // Assert
            #expect(store.account == expectedAccount)
        }
    }

}
