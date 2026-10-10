// swiftlint:disable file_length
//
//  HouseworkListStoreBulkTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
enum HouseworkListStoreBulkTest {

    @MainActor
    struct CompleteBulkCase {}
    @MainActor
    struct RemoveBulkCase {}
    @MainActor
    struct ReturnToIncompleteBulkCase {}
    @MainActor
    struct SendThanksBulkCase {}

}

private let inputCohabitantId = "cohabitantId"
private let inputAccount = Account(id: "ownUserId", userName: "own", fcmToken: nil, cohabitantId: nil)
/// `DailyHouseworkList`は先頭の家事の日付でまとめるため、全件を同じ日付にする
private let inputIndexedDate = Date.previewDate(year: 2026, month: 9, day: 25)
private let inputExpiredAt = Date.previewDate(year: 2026, month: 12, day: 25)

private extension HouseworkItem {

    static func makeForBulkTest(
        id: Int,
        state: HouseworkState,
        executorId: String? = nil,
        thanks: [String: HouseworkThanks] = [:]
    ) -> Self {
        .makeForTest(
            id: id,
            indexedDate: inputIndexedDate,
            state: state,
            executorId: executorId,
            expiredAt: inputExpiredAt,
            thanks: thanks
        )
    }

}

extension HouseworkListStoreBulkTest.CompleteBulkCase {

    @Test("登録済みの家事をまとめて完了にすると、1回の一括書き込みで全件を自分が終えた家事として更新し、件数をまとめた完了通知を1件だけ送る")
    // swiftlint:disable:next function_body_length
    func completeBulk_registeredItems_writesOnceAndSendsBulkNotification() async {
        // Arrange

        // 完了通知は今日の家事の完了でしか送らないため、家事の日付と同じ日にする
        let now = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let inputItems = [
            HouseworkItem.makeForBulkTest(id: 1, state: .incomplete),
            HouseworkItem.makeForBulkTest(id: 2, state: .incomplete),
        ]
        let expectedItems = [
            inputItems[0].updateProperties(state: .completed, executorId: inputAccount.id, executedAt: now),
            inputItems[1].updateProperties(state: .completed, executorId: inputAccount.id, executedAt: now),
        ]
        let expectedContent = PushNotificationContent(
            title: "ownさんが家事を終えました",
            message: "2件の家事が完了しました",
            data: ["type": "houseworkCompleted", "houseworkDate": "1790262000"]
        )

        await confirmation(expectedCount: 2) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(
                        insertOrUpdateItemHandler: { _, _ in
                            Issue.record()
                        },
                        insertOrUpdateItemsHandler: { items, cohabitantId in
                            // Assert

                            #expect(items == expectedItems)
                            #expect(cohabitantId == inputCohabitantId)
                            confirmation()
                        }
                    ),
                    cohabitantPushNotificationClient: .init { id, content in
                        // Assert

                        #expect(id == inputCohabitantId)
                        #expect(content == expectedContent)
                        confirmation()
                        continuation.resume()
                    },
                    calendar: .japanese,
                    items: [.makeForTest(items: inputItems)]
                )

                // Act

                Task {
                    try? await store.completeBulk(
                        targets: inputItems,
                        now: now,
                        reporter: inputAccount,
                        cohabitantId: inputCohabitantId,
                        step: .board
                    )
                }
            }
        }
    }

    @Test("一覧に無い（テンプレートから出している）家事をまとめて完了にすると、作成日時を付けて新規作成する")
    func completeBulk_unregisteredItem_writesWithCreatedAt() async throws {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 9, day: 1)
        let inputItem = HouseworkItem.makeForBulkTest(id: 1, state: .incomplete)
        let expectedItems = [
            inputItem.updateProperties(
                state: .completed,
                executorId: inputAccount.id,
                executedAt: now,
                createdAt: now
            ),
        ]

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemsHandler: { items, _ in
                    // Assert

                    #expect(items == expectedItems)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in }
            )

            // Act

            try await store.completeBulk(
                targets: [inputItem],
                now: now,
                reporter: inputAccount,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

    @Test("まとめて完了にすると、Analyticsは件数を付けて1回だけ送る")
    func completeBulk_logsOnceWithItemCount() async throws {
        // Arrange

        let inputItems = [
            HouseworkItem.makeForBulkTest(id: 1, state: .incomplete),
            HouseworkItem.makeForBulkTest(id: 2, state: .incomplete),
        ]
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemsHandler: { _, _ in }),
            cohabitantPushNotificationClient: .init { _, _ in },
            analyticsClient: .init(log: { logger.value.append($0) }),
            items: [.makeForTest(items: inputItems)]
        )
        let expected: [AnalyticsEvent] = [
            .init(
                name: "housework",
                parameters: [
                    "action": "complete",
                    "step": "board",
                    "executor_type": "self",
                    "effort": "normal",
                    "result": "success",
                ],
                numericParameters: ["item_count": 2]
            ),
        ]

        // Act

        try await store.completeBulk(
            targets: inputItems,
            now: .previewDate(year: 2026, month: 9, day: 1),
            reporter: inputAccount,
            cohabitantId: inputCohabitantId,
            step: .board
        )

        // Assert

        #expect(logger.value == expected)
    }

    @Test("まとめた書き込みに失敗すると、失敗のAnalyticsを件数を付けて1回だけ送り、完了通知は送らない")
    func completeBulk_writeFailed_logsFailureAndThrows() async {
        // Arrange

        let inputItems = [
            HouseworkItem.makeForBulkTest(id: 1, state: .incomplete),
            HouseworkItem.makeForBulkTest(id: 2, state: .incomplete),
        ]
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemsHandler: { _, _ in throw DomainError.noNetwork }),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { logger.value.append($0) }),
            items: [.makeForTest(items: inputItems)]
        )
        let expected: [AnalyticsEvent] = [
            .init(
                name: "housework",
                parameters: [
                    "action": "complete",
                    "step": "board",
                    "executor_type": "self",
                    "effort": "normal",
                    "result": "failure",
                ],
                numericParameters: ["item_count": 2]
            ),
        ]

        // Act

        await #expect(throws: DomainError.noNetwork) {
            try await store.completeBulk(
                targets: inputItems,
                now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
                reporter: inputAccount,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }

        // Assert

        #expect(logger.value == expected)
    }

    @Test("対象が空なら、書き込みもAnalyticsも完了通知も行わない")
    func completeBulk_emptyTargets_doesNothing() async throws {
        // Arrange

        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemsHandler: { _, _ in Issue.record() }),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act

        try await store.completeBulk(
            targets: [],
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            reporter: inputAccount,
            cohabitantId: inputCohabitantId,
            step: .board
        )
    }

}

extension HouseworkListStoreBulkTest.RemoveBulkCase {

    @Test("まとめてやらないにすると、1回の一括書き込みで全件をやらないに更新し、Analyticsは件数を付けて1回だけ送る")
    func removeBulk_writesOnceAndLogsOnce() async throws {
        // Arrange

        let inputItems = [
            HouseworkItem.makeForBulkTest(id: 1, state: .incomplete),
            HouseworkItem.makeForBulkTest(id: 2, state: .incomplete),
        ]
        let expectedItems = [
            inputItems[0].updateProperties(state: .notTodo),
            inputItems[1].updateProperties(state: .notTodo),
        ]
        let expectedEvents: [AnalyticsEvent] = [
            .init(
                name: "housework",
                parameters: ["action": "delete", "step": "board", "result": "success"],
                numericParameters: ["item_count": 2]
            ),
        ]
        let logger = TestBox<[AnalyticsEvent]>(value: [])

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemsHandler: { items, cohabitantId in
                    // Assert

                    #expect(items == expectedItems)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                analyticsClient: .init(log: { logger.value.append($0) }),
                items: [.makeForTest(items: inputItems)]
            )

            // Act

            try await store.removeBulk(targets: inputItems, cohabitantId: inputCohabitantId, step: .board)
        }

        // Assert

        #expect(logger.value == expectedEvents)
    }

}

extension HouseworkListStoreBulkTest.ReturnToIncompleteBulkCase {

    @Test("まとめて未完了に戻すと、1回の一括書き込みで全件を未完了に戻し、Analyticsは件数を付けて1回だけ送る")
    func returnToIncompleteBulk_writesOnceAndLogsOnce() async throws {
        // Arrange

        let inputItems = [
            HouseworkItem.makeForBulkTest(id: 1, state: .completed, executorId: "otherUserId"),
            HouseworkItem.makeForBulkTest(id: 2, state: .completed, executorId: "otherUserId"),
        ]
        let expectedItems = [
            inputItems[0].updateProperties(state: .incomplete),
            inputItems[1].updateProperties(state: .incomplete),
        ]
        let expectedEvents: [AnalyticsEvent] = [
            .init(
                name: "housework",
                parameters: ["action": "return_incomplete", "step": "board", "result": "success"],
                numericParameters: ["item_count": 2]
            ),
        ]
        let logger = TestBox<[AnalyticsEvent]>(value: [])

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemsHandler: { items, cohabitantId in
                    // Assert

                    #expect(items == expectedItems)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                analyticsClient: .init(log: { logger.value.append($0) }),
                items: [.makeForTest(items: inputItems)]
            )

            // Act

            try await store.returnToIncompleteBulk(
                targets: inputItems,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }

        // Assert

        #expect(logger.value == expectedEvents)
    }

}

extension HouseworkListStoreBulkTest.SendThanksBulkCase {

    @Test("まとめてありがとうを伝えると、まだ伝えていない完了済みの家事だけに1回の一括書き込みでコメントなしのありがとうを記録する")
    // swiftlint:disable:next function_body_length
    func sendThanksBulk_writesOnlyThankableItemsOnce() async throws {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let inputItems = [
            HouseworkItem.makeForBulkTest(id: 1, state: .completed, executorId: "otherUserId"),
            // 画面の表示がリスナーに追いつく前に、すでにありがとうを伝えていた家事
            HouseworkItem.makeForBulkTest(id: 2, state: .completed, executorId: "otherUserId"),
            // 画面の表示がリスナーに追いつく前に、未完了へ戻されていた家事
            HouseworkItem.makeForBulkTest(id: 3, state: .completed, executorId: "otherUserId"),
            HouseworkItem.makeForBulkTest(id: 4, state: .completed, executorId: "otherUserId"),
        ]
        let listenedItems = [
            inputItems[0],
            HouseworkItem.makeForBulkTest(
                id: 2,
                state: .completed,
                executorId: "otherUserId",
                thanks: [inputAccount.id: .init(comment: "ありがとう", sentAt: .distantPast)]
            ),
            HouseworkItem.makeForBulkTest(id: 3, state: .incomplete),
            inputItems[3],
        ]

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    upsertThanksHandler: { _, _, _, _ in
                        Issue.record()
                    },
                    upsertThanksBatchHandler: { houseworkIds, senderId, thanks, cohabitantId in
                        // Assert

                        #expect(houseworkIds == ["id1", "id4"])
                        #expect(senderId == inputAccount.id)
                        #expect(thanks == HouseworkThanks(comment: nil, sentAt: now))
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                items: [.makeForTest(items: listenedItems)]
            )

            // Act

            try await store.sendThanksBulk(
                targets: inputItems,
                sender: inputAccount,
                now: now,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

    @Test("まとめてありがとうを伝えると、記録した件数を付けてAnalyticsを1回だけ送り、記録したとして返す")
    func sendThanksBulk_logsOnceWithItemCountAndReturnsTrue() async throws {
        // Arrange

        let inputItems = [
            HouseworkItem.makeForBulkTest(id: 1, state: .completed, executorId: "otherUserId"),
            HouseworkItem.makeForBulkTest(
                id: 2,
                state: .completed,
                executorId: "otherUserId",
                thanks: [inputAccount.id: .init(comment: nil, sentAt: .distantPast)]
            ),
            HouseworkItem.makeForBulkTest(id: 3, state: .completed, executorId: "otherUserId"),
        ]
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(upsertThanksBatchHandler: { _, _, _, _ in }),
            analyticsClient: .init(log: { logger.value.append($0) }),
            items: [.makeForTest(items: inputItems)]
        )
        let expectedEvents: [AnalyticsEvent] = [
            .init(
                name: "housework",
                parameters: ["action": "send_thanks", "step": "board", "result": "success"],
                numericParameters: ["item_count": 2]
            ),
        ]

        // Act

        let actual = try await store.sendThanksBulk(
            targets: inputItems,
            sender: inputAccount,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            cohabitantId: inputCohabitantId,
            step: .board
        )

        // Assert

        #expect(actual == true)
        #expect(logger.value == expectedEvents)
    }

    @Test("伝えられる家事が1件も残らなければ、書き込みもAnalyticsも行わず、記録していないとして返す")
    func sendThanksBulk_noThankableItems_doesNothingAndReturnsFalse() async throws {
        // Arrange

        let inputItems = [
            HouseworkItem.makeForBulkTest(
                id: 1,
                state: .completed,
                executorId: "otherUserId",
                thanks: [inputAccount.id: .init(comment: nil, sentAt: .distantPast)]
            ),
            HouseworkItem.makeForBulkTest(id: 2, state: .incomplete),
        ]
        let store = HouseworkListStore(
            houseworkClient: .init(upsertThanksBatchHandler: { _, _, _, _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() }),
            items: [.makeForTest(items: inputItems)]
        )

        // Act

        let actual = try await store.sendThanksBulk(
            targets: inputItems,
            sender: inputAccount,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            cohabitantId: inputCohabitantId,
            step: .board
        )

        // Assert

        #expect(actual == false)
    }

    @Test("まとめた書き込みに失敗すると、失敗のAnalyticsを件数を付けて1回だけ送る")
    func sendThanksBulk_writeFailed_logsFailureAndThrows() async {
        // Arrange

        let inputItems = [
            HouseworkItem.makeForBulkTest(id: 1, state: .completed, executorId: "otherUserId"),
            HouseworkItem.makeForBulkTest(id: 2, state: .completed, executorId: "otherUserId"),
        ]
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(upsertThanksBatchHandler: { _, _, _, _ in throw DomainError.noNetwork }),
            analyticsClient: .init(log: { logger.value.append($0) }),
            items: [.makeForTest(items: inputItems)]
        )
        let expectedEvents: [AnalyticsEvent] = [
            .init(
                name: "housework",
                parameters: ["action": "send_thanks", "step": "board", "result": "failure"],
                numericParameters: ["item_count": 2]
            ),
        ]

        // Act

        await #expect(throws: DomainError.noNetwork) {
            try await store.sendThanksBulk(
                targets: inputItems,
                sender: inputAccount,
                now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }

        // Assert

        #expect(logger.value == expectedEvents)
    }

}
