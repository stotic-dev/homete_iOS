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
    struct NotifyFalseCase {}
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

    @Test("ありがとうを実行すると、家事は更新せず定型コメントの通知だけを送る")
    func perform_sendThanks() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "otherUserId",
            executedAt: .distantPast
        )
        let expectedNotification = PushNotificationContent(
            title: "\(inputAccount.userName)さんから「\(inputItem.title)」にありがとうが届きました",
            message: "ありがとう！"
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in
                    Issue.record()
                }),
                cohabitantPushNotificationClient: .init { id, content in
                    // Assert

                    #expect(id == inputCohabitantId)
                    #expect(content == expectedNotification)
                    confirmation()
                },
                items: [.makeForTest(items: [inputItem])]
            )

            // Act

            try await store.perform(
                .sendThanks,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: Date(),
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

extension HouseworkListStoreQuickActionTest.NotifyFalseCase {

    @Test("notify: falseを指定すると、完了に更新しても個別の通知は送られない")
    func perform_complete_notifyFalse_doesNotSendNotification() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let inputItem = HouseworkItem.makeForTest(id: 1, state: .incomplete)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in
                    Issue.record()
                },
                items: [.makeForTest(items: [inputItem])]
            )

            // Act

            try await store.perform(
                .complete,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: Date(),
                account: inputAccount,
                cohabitantId: inputCohabitantId,
                step: .board,
                notify: false
            )
        }
    }

    @Test("notify: falseを指定すると、ありがとうを実行しても個別の通知は送られない")
    func perform_sendThanks_notifyFalse_doesNotSendNotification() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "otherUserId"
        )
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in
                Issue.record()
            }),
            cohabitantPushNotificationClient: .init { _, _ in
                // Assert

                Issue.record()
            },
            items: [.makeForTest(items: [inputItem])]
        )

        // Act

        try await store.perform(
            .sendThanks,
            on: .init(originalItem: inputItem, isRegistered: true),
            now: Date(),
            account: inputAccount,
            cohabitantId: inputCohabitantId,
            step: .board,
            notify: false
        )
    }

}

extension HouseworkListStoreQuickActionTest.PerformBulkCase {

    @Test("複数の家事を一括で完了にすると、家事ごとに更新した上でまとめ通知を1件だけ送る")
    func performBulk_complete_updatesEachItemAndSendsBulkNotification() async {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let now = Date()
        // DailyHouseworkListは先頭要素のindexedDateをメタデータに使うため、要素ごとに
        // .nowを引くと2件目が同じ日付のリストに属さず、Store側の検索から漏れる
        let indexedDate = Date()
        let inputItems = [
            HouseworkItem.makeForTest(id: 1, indexedDate: indexedDate, state: .incomplete),
            HouseworkItem.makeForTest(id: 2, indexedDate: indexedDate, state: .incomplete),
        ]
        let expectedItems = inputItems.map {
            $0.updateProperties(
                state: .completed,
                executorId: inputAccount.id,
                executedAt: now
            )
        }
        let expectedNotification = PushNotificationContent(
            title: "\(inputAccount.userName)さんが家事を終えました",
            message: "\(inputItems.count)件の家事が完了しました"
        )

        await confirmation(expectedCount: 3) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                        // Assert

                        #expect(expectedItems.contains(item))
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }),
                    cohabitantPushNotificationClient: .init { id, content in
                        // Assert

                        #expect(id == inputCohabitantId)
                        #expect(content == expectedNotification)
                        confirmation()
                        continuation.resume()
                    },
                    items: [.makeForTest(items: inputItems)]
                )

                // Act

                Task {
                    try? await store.performBulk(
                        .complete,
                        on: inputItems.map { .init(originalItem: $0, isRegistered: true) },
                        now: now,
                        account: inputAccount,
                        cohabitantId: inputCohabitantId,
                        step: .board
                    )
                }
            }
        }
    }

    @Test("複数の家事に一括でありがとうを伝えると、家事は更新せずまとめ通知を1件だけ送る")
    func performBulk_sendThanks_sendsOnlyBulkNotification() async {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let indexedDate = Date()
        let inputItems = [
            HouseworkItem.makeForTest(
                id: 1,
                indexedDate: indexedDate,
                state: .completed,
                executorId: "otherUserId"
            ),
            HouseworkItem.makeForTest(
                id: 2,
                indexedDate: indexedDate,
                state: .completed,
                executorId: "otherUserId"
            ),
        ]
        let expectedNotification = PushNotificationContent(
            title: "\(inputAccount.userName)さんからありがとうが届きました",
            message: "\(inputItems.count)件の家事にありがとうが届きました"
        )

        await confirmation { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in
                        Issue.record()
                    }),
                    cohabitantPushNotificationClient: .init { id, content in
                        // Assert

                        #expect(id == inputCohabitantId)
                        #expect(content == expectedNotification)
                        confirmation()
                        continuation.resume()
                    },
                    items: [.makeForTest(items: inputItems)]
                )

                // Act

                Task {
                    try? await store.performBulk(
                        .sendThanks,
                        on: inputItems.map { .init(originalItem: $0, isRegistered: true) },
                        now: Date(),
                        account: inputAccount,
                        cohabitantId: inputCohabitantId,
                        step: .board
                    )
                }
            }
        }
    }

    @Test("相手に通知しないアクションを一括適用しても、まとめ通知は送られない")
    func performBulk_returnToIncomplete_doesNotSendNotification() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let indexedDate = Date()
        let inputItems = [
            HouseworkItem.makeForTest(id: 1, indexedDate: indexedDate, state: .completed),
            HouseworkItem.makeForTest(id: 2, indexedDate: indexedDate, state: .completed),
        ]

        try await confirmation(expectedCount: 2) { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in
                    Issue.record()
                },
                items: [.makeForTest(items: inputItems)]
            )

            // Act

            try await store.performBulk(
                .returnToIncomplete,
                on: inputItems.map { .init(originalItem: $0, isRegistered: true) },
                now: Date(),
                account: inputAccount,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

    @Test("対象が空の場合は、更新もまとめ通知も行わない")
    func performBulk_emptyItems_doesNothing() async throws {
        // Arrange

        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in
                Issue.record()
            }),
            cohabitantPushNotificationClient: .init { _, _ in
                Issue.record()
            }
        )

        // Act

        try await store.performBulk(
            .complete,
            on: [],
            now: Date(),
            account: inputAccount,
            cohabitantId: "cohabitantId",
            step: .board
        )
    }

}
