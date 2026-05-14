// swiftlint:disable file_length
//
//  HouseworkListStoreTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/29.
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkListStoreTest {

    private let inputId = "houseworkObserveKey"
    private let inputCohabitantId = "cohabitantId"

    @MainActor
    struct UpdateStatusCase {

        private let inputId = "houseworkObserveKey"
        private let inputCohabitantId = "cohabitantId"

    }

    @MainActor
    struct ApplyTemplateCase {

        private let inputCohabitantId = "cohabitantId"

    }

    @Test("新しい家事の登録すると、パートナーに通知を送信する")
    func register() async {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)
        let expectedNotificationContent = PushNotificationContent(
            title: "新しい家事が登録されました",
            message: inputHouseworkItem.title
        )

        await confirmation(expectedCount: 2) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                        // Assert

                        #expect(item == inputHouseworkItem)
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }),
                    cohabitantPushNotificationClient: .init { id, content in
                        // Assert

                        #expect(id == inputCohabitantId)
                        #expect(content == expectedNotificationContent)
                        confirmation()
                        continuation.resume()
                    }
                )

                // Act

                Task {
                    try await store.register(newItem: inputHouseworkItem, cohabitantId: inputCohabitantId)
                }
            }
        }
    }

}

extension HouseworkListStoreTest.UpdateStatusCase {

    @Test("家事の完了確認を依頼すると、パートナーにその旨Push通知を送信する")
    func requestReview() async {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)
        let expectedNotificationContent = PushNotificationContent(
            title: "確認が必要な家事があります",
            message: "問題なければ「\(inputHouseworkItem.title)」の完了に感謝を伝えましょう！"
        )
        let requestedAt = Date()
        let inputExecutor = "dummyExecutor"
        let updatedHouseworkItem = inputHouseworkItem.updateProperties(
            state: .pendingApproval,
            executorId: inputExecutor,
            executedAt: requestedAt
        )

        await confirmation(expectedCount: 2) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(
                        insertOrUpdateItemHandler: { item, cohabitantId in
                            // Assert

                            #expect(item == updatedHouseworkItem)
                            #expect(cohabitantId == inputCohabitantId)
                            confirmation()
                        }
                    ),
                    cohabitantPushNotificationClient: .init { id, content in
                        // Assert

                        #expect(id == inputCohabitantId)
                        #expect(content == expectedNotificationContent)
                        confirmation()
                        continuation.resume()
                    },
                    items: [.makeForTest(items: [inputHouseworkItem])]
                )

                // Act

                Task {
                    try await store.requestReview(
                        target: inputHouseworkItem,
                        now: requestedAt,
                        executor: inputExecutor,
                        cohabitantId: inputCohabitantId
                    )
                }
            }
        }
    }

    @Test("実施者、実施日をクリアして家事のステータスを未完了に戻す")
    func returnToIncomplete() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .pendingApproval,
            executorId: "dummyExecutor",
            executedAt: .distantPast
        )
        let updatedHouseworkItem = inputHouseworkItem.updateProperties(
            state: .incomplete,
            executorId: nil,
            executedAt: nil
        )

        try await confirmation(expectedCount: 1) { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, cohabitantId in
                        // Assert

                        #expect(item == updatedHouseworkItem)
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in
                    Issue.record()
                },
                items: [.makeForTest(items: [inputHouseworkItem])]
            )

            // Act

            try await store.returnToIncomplete(target: inputHouseworkItem, cohabitantId: inputCohabitantId)
        }
    }

    @Test("家事削除時は家事を削除するAPIを実行する")
    func remove() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(removeItemHandler: { item, cohabitantId in
                    // Assert

                    #expect(item == inputHouseworkItem)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .previewValue,
                items: [.makeForTest(items: [inputHouseworkItem])]
            )

            // Act

            try await store.remove(target: inputHouseworkItem, cohabitantId: inputCohabitantId)
        }
    }

    @Test("家事を承認すると、承認情報を更新しパートナーに通知を送信する")
    // swiftlint:disable:next function_body_length
    func approved() async {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .pendingApproval,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let approvedAt = Date()
        let inputReviewer = Account(
            id: "reviewerId",
            userName: "レビュアー",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let inputComment = "お疲れ様でした！"
        let updatedHouseworkItem = inputHouseworkItem.updateApproved(
            at: approvedAt,
            reviewer: inputReviewer.id,
            comment: inputComment
        )
        let expectedNotificationContent = PushNotificationContent.approvedMessage(
            reviwerName: inputReviewer.userName,
            houseworkTitle: inputHouseworkItem.title,
            comment: inputComment
        )

        await confirmation(expectedCount: 2) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(
                        insertOrUpdateItemHandler: { item, cohabitantId in
                            // Assert

                            #expect(item == updatedHouseworkItem)
                            #expect(cohabitantId == inputCohabitantId)
                            confirmation()
                        }
                    ),
                    cohabitantPushNotificationClient: .init { id, content in
                        // Assert

                        #expect(id == inputCohabitantId)
                        #expect(content == expectedNotificationContent)
                        confirmation()
                        continuation.resume()
                    },
                    items: [.makeForTest(items: [inputHouseworkItem])]
                )

                // Act

                Task {
                    try await store.approved(
                        target: inputHouseworkItem,
                        now: approvedAt,
                        reviwer: inputReviewer,
                        comment: inputComment,
                        cohabitantId: inputCohabitantId
                    )
                }
            }
        }
    }

    @Test("家事を却下すると、却下情報を更新しパートナーに通知を送信する")
    // swiftlint:disable:next function_body_length
    func rejected() async {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .pendingApproval,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let rejectedAt = Date()
        let inputReviewer = Account(
            id: "reviewerId",
            userName: "レビュアー",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let inputComment = "もう一度確認してください"
        let updatedHouseworkItem = inputHouseworkItem.updateRejected(
            at: rejectedAt,
            reviewer: inputReviewer.id,
            comment: inputComment
        )
        let expectedNotificationContent = PushNotificationContent.rejectedMessage(
            reviwerName: inputReviewer.userName,
            houseworkTitle: inputHouseworkItem.title,
            comment: inputComment
        )

        await confirmation(expectedCount: 2) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(
                        insertOrUpdateItemHandler: { item, cohabitantId in
                            // Assert

                            #expect(item == updatedHouseworkItem)
                            #expect(cohabitantId == inputCohabitantId)
                            confirmation()
                        }
                    ),
                    cohabitantPushNotificationClient: .init { id, content in
                        // Assert

                        #expect(id == inputCohabitantId)
                        #expect(content == expectedNotificationContent)
                        confirmation()
                        continuation.resume()
                    },
                    items: [.makeForTest(items: [inputHouseworkItem])]
                )

                // Act

                Task {
                    try await store.rejected(
                        target: inputHouseworkItem,
                        now: rejectedAt,
                        reviwer: inputReviewer,
                        comment: inputComment,
                        cohabitantId: inputCohabitantId
                    )
                }
            }
        }
    }

}

extension HouseworkListStoreTest.ApplyTemplateCase {

    @Test("テンプレート適用時、対象範囲のincomplete家事をremoveItemで削除する")
    func applyTemplate_removesIncompleteItemsInRange() async throws {
        // Arrange

        let calendar = Calendar.japanese
        let now = Date.previewDate(year: 2026, month: 5, day: 9)
        let targetItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 10)
        )
        let plan = ApplyPlan.make(
            days: [],
            cohabitantId: inputCohabitantId,
            incompleteItems: [targetItem],
            now: now,
            calendar: calendar
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    removeItemHandler: { item, cohabitantId in
                        // Assert

                        #expect(item == targetItem)
                        #expect(cohabitantId == self.inputCohabitantId)
                        confirmation()
                    }
                )
            )

            // Act

            try await store.applyTemplate(plan: plan)
        }
    }

    @Test("テンプレート適用時、テンプレートのアイテムを該当曜日に書き込む")
    func applyTemplate_writesTemplateItemsToMatchingWeekday() async throws {
        // Arrange

        let calendar = Calendar.japanese
        // 2026-05-09 は土曜日（dayOfWeek=6）
        let now = Date.previewDate(year: 2026, month: 5, day: 9)
        let inputDays: [HouseworkTemplateDay] = [
            .init(dayOfWeek: 6, items: [.init(title: "週末掃除", point: 30)])
        ]
        let fixedItemId = "generatedId"
        let plan = ApplyPlan.make(
            days: inputDays,
            cohabitantId: inputCohabitantId,
            incompleteItems: [],
            now: now,
            calendar: calendar
        )
        let expectedItem = HouseworkItem(
            id: fixedItemId,
            indexedDate: HouseworkIndexedDate(value: Date.previewDate(year: 2026, month: 5, day: 9)),
            title: "週末掃除",
            point: 30,
            state: .incomplete,
            executorId: nil,
            executedAt: nil,
            reviewerId: nil,
            approvedAt: nil,
            reviewerComment: nil,
            expiredAt: Date.previewDate(year: 2027, month: 5, day: 9)
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, cohabitantId in
                        // Assert

                        #expect(item == expectedItem)
                        #expect(cohabitantId == self.inputCohabitantId)
                        confirmation()
                    }
                ),
                idGenerator: { fixedItemId }
            )

            // Act

            try await store.applyTemplate(plan: plan)
        }
    }

}
