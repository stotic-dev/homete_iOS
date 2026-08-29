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
    struct RequestReviewCase {}
    @MainActor
    struct RemoveCase {}
    @MainActor
    struct ApproveCase {}
    @MainActor
    struct RejectCase {}
    @MainActor
    struct ReturnToIncompleteCase {}
    @MainActor
    struct NotifyFalseCase {}
    @MainActor
    struct PerformBulkCase {}

}

extension HouseworkListStoreQuickActionTest.RequestReviewCase {

    @Test("登録済みの家事に承認依頼を行うと、未完了から承認待ちに更新する")
    func perform_requestReview_registeredItem() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let now = Date()
        let inputItem = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let expected = inputItem.updateProperties(
            state: .pendingApproval,
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
                .requestReview,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: now,
                account: inputAccount,
                cohabitantId: inputCohabitantId
            )
        }
    }

    @Test("未登録（テンプレート由来）の家事に承認依頼を行うと、新規ドキュメントとして保存する")
    func perform_requestReview_unregisteredItem() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let now = Date()
        let inputItem = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let expected = inputItem.updateProperties(
            state: .pendingApproval,
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
                .requestReview,
                on: .init(originalItem: inputItem, isRegistered: false),
                now: now,
                account: inputAccount,
                cohabitantId: inputCohabitantId
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
                cohabitantId: inputCohabitantId
            )
        }
    }

}

extension HouseworkListStoreQuickActionTest.ApproveCase {

    @Test("ありがとうを実行すると、固定の定型コメントで承認して完了状態にする")
    func perform_approve() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let now = Date()
        let executedAt = Date.distantPast
        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .pendingApproval,
            executorId: "otherUserId",
            executedAt: executedAt
        )
        let expected = inputItem.updateProperties(
            state: .completed,
            executorId: "otherUserId",
            executedAt: executedAt,
            reviewerId: inputAccount.id,
            approvedAt: now,
            reviewerComment: "ありがとう！"
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
                .approve,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: now,
                account: inputAccount,
                cohabitantId: inputCohabitantId
            )
        }
    }

}

extension HouseworkListStoreQuickActionTest.RejectCase {

    @Test("再確認依頼を実行すると、固定の定型コメントで未完了に差し戻す")
    func perform_reject() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let now = Date()
        let executedAt = Date.distantPast
        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .pendingApproval,
            executorId: "otherUserId",
            executedAt: executedAt
        )
        let expected = inputItem.updateProperties(
            state: .incomplete,
            executorId: "otherUserId",
            executedAt: executedAt,
            reviewerId: inputAccount.id,
            approvedAt: now,
            reviewerComment: "再確認をお願いします"
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
                .reject,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: now,
                account: inputAccount,
                cohabitantId: inputCohabitantId
            )
        }
    }

}

extension HouseworkListStoreQuickActionTest.ReturnToIncompleteCase {

    @Test("差し戻しを実行すると、実施者・確認情報をクリアして未完了に戻す")
    func perform_returnToIncomplete() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "otherUserId",
            executedAt: .distantPast,
            reviewerId: "reviewerUserId",
            approvedAt: .distantPast,
            reviewerComment: "ありがとう！"
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
                cohabitantId: inputCohabitantId
            )
        }
    }

}

extension HouseworkListStoreQuickActionTest.NotifyFalseCase {

    @Test("notify: falseを指定すると、承認待ちへの更新をしても個別の通知は送られない")
    func perform_requestReview_notifyFalse_doesNotSendNotification() async throws {
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
                .requestReview,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: Date(),
                account: inputAccount,
                cohabitantId: inputCohabitantId,
                notify: false
            )
        }
    }

    @Test("notify: falseを指定すると、ありがとうを実行しても個別の通知は送られない")
    func perform_approve_notifyFalse_doesNotSendNotification() async throws {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .pendingApproval,
            executorId: "otherUserId"
        )

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
                .approve,
                on: .init(originalItem: inputItem, isRegistered: true),
                now: Date(),
                account: inputAccount,
                cohabitantId: inputCohabitantId,
                notify: false
            )
        }
    }

}

extension HouseworkListStoreQuickActionTest.PerformBulkCase {

    @Test("複数の家事にありがとうを一括適用すると、家事ごとに更新した上でまとめ通知を1件だけ送る")
    func performBulk_approve_updatesEachItemAndSendsBulkNotification() async {
        // Arrange

        let inputCohabitantId = "cohabitantId"
        let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
        let now = Date()
        let executedAt = Date.distantPast
        // DailyHouseworkListは先頭要素のindexedDateをメタデータに使うため、要素ごとに
        // .nowを引くと2件目が同じ日付のリストに属さず、Store側の検索から漏れる
        let indexedDate = Date()
        let inputItems = [
            HouseworkItem.makeForTest(
                id: 1,
                indexedDate: indexedDate,
                state: .pendingApproval,
                executorId: "otherUserId",
                executedAt: executedAt
            ),
            HouseworkItem.makeForTest(
                id: 2,
                indexedDate: indexedDate,
                state: .pendingApproval,
                executorId: "otherUserId",
                executedAt: executedAt
            ),
        ]
        let expectedItems = inputItems.map {
            $0.updateProperties(
                state: .completed,
                executorId: "otherUserId",
                executedAt: executedAt,
                reviewerId: inputAccount.id,
                approvedAt: now,
                reviewerComment: "ありがとう！"
            )
        }
        let expectedNotification = PushNotificationContent.approvedBulkMessage(
            reviwerName: inputAccount.userName,
            count: inputItems.count
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
                        .approve,
                        on: inputItems.map { .init(originalItem: $0, isRegistered: true) },
                        now: now,
                        account: inputAccount,
                        cohabitantId: inputCohabitantId
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
                cohabitantId: inputCohabitantId
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
            .approve,
            on: [],
            now: Date(),
            account: inputAccount,
            cohabitantId: "cohabitantId"
        )
    }

}
