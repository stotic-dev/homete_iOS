// swiftlint:disable file_length
//
//  HouseworkListStore+QuickActionTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

@MainActor
enum HouseworkListStoreQuickActionTest {

    @MainActor
    struct CompleteCase {}
    @MainActor
    struct RemoveCase {}
    @MainActor
    struct SendThanksCase {}
    @MainActor
    struct ReturnToIncompleteCase {}
    @MainActor
    struct PerformBulkCase {}

}

extension HouseworkListStoreQuickActionTest.CompleteCase {

    @Test("登録済みの家事を完了にすると、実施者と実施日時を付けて完了に更新する")
    func perform_complete_registeredItem() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let now = Date()
        let inputItem = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let expected = inputItem.updateProperties(
            state: .completed,
            executorId: inputAccount.id,
            executedAt: now
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                    // Assert

                    #expect(item == expected)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .previewValue,
                items: [.makeForTest(items: [inputItem])]
            )

            // Act

            try await store.perform(
                .complete,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: now,
                account: inputAccount,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

    @Test("未登録（テンプレート由来）の家事を完了にすると、新規ドキュメントとして保存する")
    func perform_complete_unregisteredItem() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let now = Date()
        let inputItem = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let expected = inputItem.updateProperties(
            state: .completed,
            executorId: inputAccount.id,
            executedAt: now,
            createdAt: now
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                    // Assert

                    #expect(item == expected)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .previewValue,
                items: []
            )

            // Act

            try await store.perform(
                .complete,
                on: .init(originalItem: inputItem, isRegistered: false),
                now: now,
                account: inputAccount,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

}

extension HouseworkListStoreQuickActionTest.RemoveCase {

    @Test("やらないを実行すると、家事をやらない状態に更新する")
    func perform_remove() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let inputItem = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let expected = inputItem.updateProperties(state: .notTodo)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                    // Assert

                    #expect(item == expected)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .previewValue,
                items: [.makeForTest(items: [inputItem])]
            )

            // Act

            try await store.perform(
                .remove,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: Date(),
                account: inputAccount,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

}

extension HouseworkListStoreQuickActionTest.SendThanksCase {

    @Test("ありがとうを実行すると、コメントなしのありがとうを記録し、通知は送らない")
    func perform_sendThanks() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let inputNow = Date(timeIntervalSince1970: 1000)
        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "otherUserId",
            executedAt: .distantPast
        )
        let expectedThanks = HouseworkThanks(comment: nil, sentAt: inputNow)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { _, _ in
                        Issue.record()
                    },
                    upsertThanksHandler: { houseworkId, senderId, thanks, cohabitantId in
                        // Assert

                        #expect(houseworkId == inputItem.id)
                        #expect(senderId == inputAccount.id)
                        #expect(thanks == expectedThanks)
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in
                    Issue.record()
                },
                items: [.makeForTest(items: [inputItem])]
            )

            // Act

            try await store.perform(
                .sendThanks,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: inputNow,
                account: inputAccount,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

}

extension HouseworkListStoreQuickActionTest.ReturnToIncompleteCase {

    @Test("未完了に戻すを実行すると、実施者情報をクリアして未完了に戻す")
    func perform_returnToIncomplete() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "otherUserId",
            executedAt: .distantPast
        )
        let expected = inputItem.updateProperties(state: .incomplete)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                    // Assert

                    #expect(item == expected)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in
                    Issue.record()
                },
                items: [.makeForTest(items: [inputItem])]
            )

            // Act

            try await store.perform(
                .returnToIncomplete,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: Date(),
                account: inputAccount,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

}

extension HouseworkListStoreQuickActionTest.PerformBulkCase {

    @Test("一括で完了にすると、選んだ家事をまとめて1回で書き込む")
    func performBulk_complete_writesOnce() async throws {
        // Arrange

        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let now = Date.previewDate(year: 2026, month: 9, day: 1)
        let indexedDate = Date.previewDate(year: 2026, month: 9, day: 25)
        let inputItems = [
            HouseworkItem.makeForTest(id: 1, indexedDate: indexedDate, state: .incomplete),
            HouseworkItem.makeForTest(id: 2, indexedDate: indexedDate, state: .incomplete),
        ]
        let expectedItems = [
            inputItems[0].updateProperties(state: .completed, executorId: inputAccount.id, executedAt: now),
            inputItems[1].updateProperties(state: .completed, executorId: inputAccount.id, executedAt: now),
        ]

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { _, _ in
                        Issue.record()
                    },
                    insertOrUpdateItemsHandler: { items, _ in
                        // Assert

                        #expect(items == expectedItems)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in },
                items: [.makeForTest(items: inputItems)]
            )

            // Act

            try await store.performBulk(
                .complete,
                on: inputItems.map { .init(originalItem: $0, isRegistered: true) },
                now: now,
                account: inputAccount,
                cohabitantId: "cohabitantId",
                step: .board
            )
        }
    }

    @Test("一括でありがとうを伝えると、選んだ家事にまとめて1回で記録し、初めて記録したとして返す")
    func performBulk_sendThanks_writesOnceAndReturnsTrue() async throws {
        // Arrange

        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let indexedDate = Date.previewDate(year: 2026, month: 9, day: 25)
        let inputItems = [
            HouseworkItem.makeForTest(id: 1, indexedDate: indexedDate, state: .completed, executorId: "otherUserId"),
            HouseworkItem.makeForTest(id: 2, indexedDate: indexedDate, state: .completed, executorId: "otherUserId"),
        ]

        let actual = try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    upsertThanksHandler: { _, _, _, _ in
                        Issue.record()
                    },
                    upsertThanksBatchHandler: { houseworkIds, _, _, _ in
                        // Assert

                        #expect(houseworkIds == ["id1", "id2"])
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                items: [.makeForTest(items: inputItems)]
            )

            // Act

            return try await store.performBulk(
                .sendThanks,
                on: inputItems.map { .init(originalItem: $0, isRegistered: true) },
                now: Date(),
                account: inputAccount,
                cohabitantId: "cohabitantId",
                step: .board
            )
        }

        // Assert

        #expect(actual == true)
    }

    @Test(
        "ありがとう以外のアクションを一括で適用すると、選んだ家事をまとめて1回で書き込み、ありがとうを記録したとして返さない",
        arguments: [
            (HouseworkQuickAction.remove, HouseworkState.incomplete, HouseworkState.notTodo),
            (.returnToIncomplete, .completed, .incomplete),
        ]
    )
    func performBulk_otherThanThanks_writesOnceAndReturnsFalse(
        action: HouseworkQuickAction,
        inputState: HouseworkState,
        expectedState: HouseworkState
    ) async throws {
        // Arrange

        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let indexedDate = Date.previewDate(year: 2026, month: 9, day: 25)
        let inputItems = [
            HouseworkItem.makeForTest(id: 1, indexedDate: indexedDate, state: inputState),
            HouseworkItem.makeForTest(id: 2, indexedDate: indexedDate, state: inputState),
        ]
        let expectedItems = [
            inputItems[0].updateProperties(state: expectedState),
            inputItems[1].updateProperties(state: expectedState),
        ]

        let actual = try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemsHandler: { items, _ in
                    // Assert

                    #expect(items == expectedItems)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                items: [.makeForTest(items: inputItems)]
            )

            // Act

            return try await store.performBulk(
                action,
                on: inputItems.map { .init(originalItem: $0, isRegistered: true) },
                now: Date(),
                account: inputAccount,
                cohabitantId: "cohabitantId",
                step: .board
            )
        }

        // Assert

        #expect(actual == false)
    }

}
