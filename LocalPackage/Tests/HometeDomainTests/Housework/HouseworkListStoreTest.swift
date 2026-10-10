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

    @Test("新しい家事をまとめて登録すると作成日時を揃えて1回の一括書き込みだけを行い、パートナーには通知を送らない")
    func register() async throws {
        // Arrange

        let inputNow = Date(timeIntervalSince1970: 1000)
        let inputDate = Date(timeIntervalSince1970: 0)
        let inputEntries = [
            NewHouseworkEntry(
                item: .makeForTest(id: 1, indexedDate: inputDate, expiredAt: inputDate),
                source: .frequent
            ),
            NewHouseworkEntry(
                item: .makeForTest(id: 2, indexedDate: inputDate, expiredAt: inputDate),
                source: .manual
            ),
        ]
        let expected = [
            HouseworkItem.makeForTest(id: 1, indexedDate: inputDate, expiredAt: inputDate, createdAt: inputNow),
            HouseworkItem.makeForTest(id: 2, indexedDate: inputDate, expiredAt: inputDate, createdAt: inputNow),
        ]

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemsHandler: { items, cohabitantId in
                    // Assert

                    #expect(items == expected)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                now: { inputNow }
            )

            // Act

            try await store.register(
                newItems: inputEntries,
                cohabitantId: inputCohabitantId,
                step: .board,
                memoLimitPolicy: .free
            )
        }
    }

    @Test("登録する家事が0件の場合は、書き込みを行わない")
    func registerWithNoItemsDoesNothing() async throws {
        // Arrange

        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemsHandler: { _, _ in Issue.record() }),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() }
        )

        // Act

        try await store.register(newItems: [], cohabitantId: inputCohabitantId, step: .board, memoLimitPolicy: .free)
    }

}

extension HouseworkListStoreTest.UpdateStatusCase {

    @Test("家事を完了にすると、ふりかえり通知の予約を兼ねた完了通知を送る")
    // swiftlint:disable:next function_body_length
    func complete() async {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .previewDate(year: 2026, month: 9, day: 25)
        )
        let inputExecutor = Account(
            id: "dummyExecutor",
            userName: "じっこうしゃ",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let expectedContent = PushNotificationContent(
            message: .completed(executorName: "じっこうしゃ", houseworkTitle: inputHouseworkItem.title, comment: ""),
            completedData: .init(houseworkDate: Date(timeIntervalSince1970: 1_790_262_000))
        )
        let completedAt = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let updatedHouseworkItem = inputHouseworkItem.updateProperties(
            state: .completed,
            executorId: inputExecutor.id,
            executedAt: completedAt
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
                        #expect(content == expectedContent)
                        confirmation()
                        continuation.resume()
                    },
                    calendar: .japanese,
                    items: [.makeForTest(items: [inputHouseworkItem])]
                )

                // Act

                Task {
                    try await store.complete(
                        target: inputHouseworkItem,
                        now: completedAt,
                        reporter: inputExecutor,
                        executors: [.init(userId: inputExecutor.id, percentage: 100, point: inputHouseworkItem.point)],
                        effort: .normal,
                        executorNames: [inputExecutor.userName],
                        comment: "",
                        cohabitantId: inputCohabitantId,
                        isRegistered: true,
                        step: .board
                    )
                }
            }
        }
    }

    @Test("頑張り度を選んで完了にすると、上乗せ前のポイントのまま頑張り度と上乗せ後の配分を保存する")
    func complete_withEffort_savesEffortAndBoostedExecutors() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1, point: 10)
        let inputExecutor = Account(
            id: "dummyExecutor",
            userName: "じっこうしゃ",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let completedAt = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let expectedItem = inputHouseworkItem.updateProperties(
            state: .completed,
            executors: [.init(userId: inputExecutor.id, percentage: 100, point: 12)],
            effort: .hard,
            executedAt: completedAt
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, _ in
                        // Assert

                        #expect(item == expectedItem)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                calendar: .japanese,
                items: [.makeForTest(items: [inputHouseworkItem])]
            )

            // Act

            try await store.complete(
                target: inputHouseworkItem,
                now: completedAt,
                reporter: inputExecutor,
                executors: [.init(userId: inputExecutor.id, percentage: 100, point: 12)],
                effort: .hard,
                executorNames: [inputExecutor.userName],
                comment: "",
                cohabitantId: inputCohabitantId,
                isRegistered: true,
                step: .detail,
                notify: false
            )
        }
    }

    @Test("頑張り度を選んで完了にすると、Analyticsに頑張り度を送る")
    func complete_withEffort_logsEffort() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1, point: 10)
        let inputExecutor = Account(
            id: "dummyExecutor",
            userName: "じっこうしゃ",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in }),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            calendar: .japanese,
            items: [.makeForTest(items: [inputHouseworkItem])]
        )

        // Act

        try await store.complete(
            target: inputHouseworkItem,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            reporter: inputExecutor,
            executors: [.init(userId: inputExecutor.id, percentage: 100, point: 15)],
            effort: .veryHard,
            executorNames: [inputExecutor.userName],
            comment: "",
            cohabitantId: inputCohabitantId,
            isRegistered: true,
            step: .detail,
            notify: false
        )

        // Assert

        #expect(logger.value == [
            .housework(.complete(step: .detail, executorType: .ownOnly, effort: .veryHard, isSuccess: true)),
        ])
    }

    @Test("テンプレートから生成された家事を完了にすると、ふりかえり通知の予約を兼ねた完了通知を送る")
    // swiftlint:disable:next function_body_length
    func complete_with_created_template() async {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .previewDate(year: 2026, month: 9, day: 25)
        )
        let inputExecutor = Account(
            id: "dummyExecutor",
            userName: "じっこうしゃ",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let expectedContent = PushNotificationContent(
            message: .completed(executorName: "じっこうしゃ", houseworkTitle: inputHouseworkItem.title, comment: ""),
            completedData: .init(houseworkDate: Date(timeIntervalSince1970: 1_790_262_000))
        )
        let completedAt = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let updatedHouseworkItem = inputHouseworkItem.updateProperties(
            state: .completed,
            executorId: inputExecutor.id,
            executedAt: completedAt,
            createdAt: completedAt
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
                        #expect(content == expectedContent)
                        confirmation()
                        continuation.resume()
                    },
                    calendar: .japanese,
                    items: []
                )

                // Act

                Task {
                    try await store.complete(
                        target: inputHouseworkItem,
                        now: completedAt,
                        reporter: inputExecutor,
                        executors: [.init(userId: inputExecutor.id, percentage: 100, point: inputHouseworkItem.point)],
                        effort: .normal,
                        executorNames: [inputExecutor.userName],
                        comment: "",
                        cohabitantId: inputCohabitantId,
                        isRegistered: false,
                        step: .board
                    )
                }
            }
        }
    }

    @Test("他の人を担当者にして完了にすると、代わりに記録したことが分かる完了通知にコメントを添えて送る")
    // swiftlint:disable:next function_body_length
    func complete_proxyWithComment() async {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .previewDate(year: 2026, month: 9, day: 25),
            point: 10
        )
        let inputReporter = Account(
            id: "reporter",
            userName: "きろくしゃ",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let inputExecutors = [
            HouseworkExecutor(userId: "reporter", percentage: 60, point: 6),
            HouseworkExecutor(userId: "partner", percentage: 40, point: 4),
        ]
        let completedAt = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let expectedItem = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: .previewDate(year: 2026, month: 9, day: 25)),
            title: "title",
            point: 10,
            state: .completed,
            executors: [
                HouseworkExecutor(userId: "reporter", percentage: 60, point: 6),
                HouseworkExecutor(userId: "partner", percentage: 40, point: 4),
            ],
            effort: .normal,
            executedAt: completedAt,
            expiredAt: inputHouseworkItem.expiredAt,
            templateHouseworkItemId: nil
        )
        let expectedContent = PushNotificationContent(
            message: .proxyCompleted(
                reporterName: "きろくしゃ",
                executorNames: ["きろくしゃ", "パートナー"],
                houseworkTitle: "title",
                comment: "一緒に片付けました"
            ),
            completedData: .init(houseworkDate: Date(timeIntervalSince1970: 1_790_262_000))
        )

        await confirmation(expectedCount: 2) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(
                        insertOrUpdateItemHandler: { item, cohabitantId in
                            // Assert

                            #expect(item == expectedItem)
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
                    items: [.makeForTest(items: [inputHouseworkItem])]
                )

                // Act

                Task {
                    try await store.complete(
                        target: inputHouseworkItem,
                        now: completedAt,
                        reporter: inputReporter,
                        executors: inputExecutors,
                        effort: .normal,
                        executorNames: ["きろくしゃ", "パートナー"],
                        comment: "一緒に片付けました",
                        cohabitantId: inputCohabitantId,
                        isRegistered: true,
                        step: .detail
                    )
                }
            }
        }
    }

    @Test("もう一度やったにすると、同じ日・同じ内容の完了済みの家事を、テンプレートと紐づけずに新しいIDで登録する")
    func redo_insertsNewCompletedItem() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .previewDate(year: 2026, month: 9, day: 25),
            title: "洗濯",
            point: 20,
            state: .completed,
            executorId: "otherExecutor",
            executedAt: .previewDate(year: 2026, month: 9, day: 25, hour: 8),
            expiredAt: .previewDate(year: 2026, month: 12, day: 25),
            templateHouseworkItemId: .init(id: "templateItemId")
        )
        let inputExecutor = Account(id: "dummyExecutor", userName: "", fcmToken: nil, cohabitantId: inputCohabitantId)
        let redoneAt = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let expectedItem = HouseworkItem(
            id: "newItemId",
            indexedDate: .init(value: .previewDate(year: 2026, month: 9, day: 25)),
            title: "洗濯",
            point: 20,
            state: .completed,
            executorId: "dummyExecutor",
            executedAt: redoneAt,
            expiredAt: .previewDate(year: 2026, month: 12, day: 25),
            templateHouseworkItemId: nil,
            createdAt: redoneAt
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, cohabitantId in
                        // Assert

                        #expect(item == expectedItem)
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in },
                items: [.makeForTest(items: [inputHouseworkItem])],
                idGenerator: { "newItemId" }
            )

            // Act

            try await store.redo(
                target: inputHouseworkItem,
                now: redoneAt,
                executor: inputExecutor,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

    @Test("もう一度やったにすると、ふりかえり通知の予約を兼ねた完了通知を送る")
    func redo_sendsCompletedNotification() async {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .previewDate(year: 2026, month: 9, day: 25),
            state: .completed,
            executorId: "otherExecutor"
        )
        let inputExecutor = Account(
            id: "dummyExecutor",
            userName: "じっこうしゃ",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let expectedContent = PushNotificationContent(
            message: .completed(executorName: "じっこうしゃ", houseworkTitle: inputHouseworkItem.title, comment: ""),
            completedData: .init(houseworkDate: Date(timeIntervalSince1970: 1_790_262_000))
        )

        await confirmation { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in }),
                    cohabitantPushNotificationClient: .init { id, content in
                        // Assert

                        #expect(id == inputCohabitantId)
                        #expect(content == expectedContent)
                        confirmation()
                        continuation.resume()
                    },
                    calendar: .japanese,
                    items: [.makeForTest(items: [inputHouseworkItem])]
                )

                // Act

                Task {
                    try await store.redo(
                        target: inputHouseworkItem,
                        now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
                        executor: inputExecutor,
                        cohabitantId: inputCohabitantId,
                        step: .board
                    )
                }
            }
        }
    }

    @Test("手伝った人を足すと、完了の記録を保ったまま担当者の配分を入れ替えて保存し、通知は送らない")
    func addHelpers_savesExecutorsKeepingCompletionRecord() async throws {
        // Arrange

        let completedAt = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let expiredAt = Date.previewDate(year: 2026, month: 10, day: 25, hour: 10)
        let inputThanks = ["userB": HouseworkThanks(comment: "ありがとう", sentAt: completedAt)]
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: completedAt,
            point: 10,
            state: .completed,
            executors: [.init(userId: "own", percentage: 100, point: 12)],
            effort: .hard,
            executedAt: completedAt,
            expiredAt: expiredAt,
            thanks: inputThanks,
            createdAt: completedAt
        )
        let inputExecutors: [HouseworkExecutor] = [
            .init(userId: "own", percentage: 50, point: 6),
            .init(userId: "userB", percentage: 50, point: 6),
        ]
        let expectedItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: completedAt,
            point: 10,
            state: .completed,
            executors: inputExecutors,
            effort: .hard,
            executedAt: completedAt,
            expiredAt: expiredAt,
            thanks: inputThanks,
            createdAt: completedAt
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, _ in
                        // Assert

                        #expect(item == expectedItem)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                calendar: .japanese,
                items: [.makeForTest(items: [inputHouseworkItem])]
            )

            // Act

            try await store.addHelpers(
                target: inputHouseworkItem,
                executors: inputExecutors,
                cohabitantId: inputCohabitantId,
                step: .detail
            )
        }
    }

    @Test("手伝った人を足すと、Analyticsに手伝った人の追加を送る")
    func addHelpers_logsAddHelper() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            point: 10,
            state: .completed,
            executors: [.init(userId: "own", percentage: 100, point: 10)],
            executedAt: .previewDate(year: 2026, month: 9, day: 25, hour: 10)
        )
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in }),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            calendar: .japanese,
            items: [.makeForTest(items: [inputHouseworkItem])]
        )

        // Act

        try await store.addHelpers(
            target: inputHouseworkItem,
            executors: [
                .init(userId: "own", percentage: 50, point: 5),
                .init(userId: "userB", percentage: 50, point: 5),
            ],
            cohabitantId: inputCohabitantId,
            step: .detail
        )

        // Assert

        #expect(logger.value == [.housework(.addHelper(step: .detail, isSuccess: true))])
    }

    @Test("リスナーの一覧に最新の家事が無くても、手元の家事に手伝った人を足して保存する")
    func addHelpers_itemNotInList_savesWithLocalItem() async throws {
        // Arrange

        let completedAt = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: completedAt,
            point: 10,
            state: .completed,
            executors: [.init(userId: "own", percentage: 100, point: 10)],
            executedAt: completedAt
        )
        let inputExecutors: [HouseworkExecutor] = [
            .init(userId: "own", percentage: 50, point: 5),
            .init(userId: "userB", percentage: 50, point: 5),
        ]
        let expectedItem = inputHouseworkItem.updateExecutors(inputExecutors)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, _ in
                        // Assert

                        #expect(item == expectedItem)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                calendar: .japanese,
                items: []
            )

            // Act

            try await store.addHelpers(
                target: inputHouseworkItem,
                executors: inputExecutors,
                cohabitantId: inputCohabitantId,
                step: .detail
            )
        }
    }

    @Test("画面を開いている間に合計ポイントが変わった家事には、手伝った人を足さずAnalyticsも送らない")
    func addHelpers_earnedPointChanged_doesNothing() async throws {
        // Arrange

        let completedAt = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: completedAt,
            point: 10,
            state: .completed,
            executors: [.init(userId: "own", percentage: 100, point: 10)],
            executedAt: completedAt
        )
        // 画面を開いている間に同居人が「がんばった」で完了をやり直し、合計が12ptに増えた家事
        let latestHouseworkItem = inputHouseworkItem.updateCompleted(
            at: completedAt,
            executors: [.init(userId: "own", percentage: 100, point: 12)],
            effort: .hard
        )
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in Issue.record() }),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            calendar: .japanese,
            items: [.makeForTest(items: [latestHouseworkItem])]
        )

        // Act

        try await store.addHelpers(
            target: inputHouseworkItem,
            executors: [
                .init(userId: "own", percentage: 50, point: 5),
                .init(userId: "userB", percentage: 50, point: 5),
            ],
            cohabitantId: inputCohabitantId,
            step: .detail
        )

        // Assert

        #expect(logger.value.isEmpty)
    }

    @Test("画面を開いている間に未完了へ戻された家事には、手伝った人を足さずAnalyticsも送らない")
    func addHelpers_returnedToIncomplete_doesNothing() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            point: 10,
            state: .completed,
            executors: [.init(userId: "own", percentage: 100, point: 10)],
            executedAt: .previewDate(year: 2026, month: 9, day: 25, hour: 10)
        )
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in Issue.record() }),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            calendar: .japanese,
            items: [.makeForTest(items: [inputHouseworkItem.updateIncomplete()])]
        )

        // Act

        try await store.addHelpers(
            target: inputHouseworkItem,
            executors: [
                .init(userId: "own", percentage: 50, point: 5),
                .init(userId: "userB", percentage: 50, point: 5),
            ],
            cohabitantId: inputCohabitantId,
            step: .detail
        )

        // Assert

        #expect(logger.value.isEmpty)
    }

    @Test("実施者、実施日をクリアして家事のステータスを未完了に戻す")
    func returnToIncomplete() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
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

            try await store.returnToIncomplete(
                target: inputHouseworkItem,
                cohabitantId: inputCohabitantId,
                step: .detail
            )
        }
    }

    @Test("リスナーの一覧に最新の家事が無くても、手元の家事を未完了に戻して保存する")
    func returnToIncomplete_itemNotInList_savesWithLocalItem() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "dummyExecutor",
            executedAt: .distantPast
        )
        let expectedItem = inputHouseworkItem.updateIncomplete()

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, _ in
                        // Assert

                        #expect(item == expectedItem)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                items: []
            )

            // Act

            try await store.returnToIncomplete(
                target: inputHouseworkItem,
                cohabitantId: inputCohabitantId,
                step: .detail
            )
        }
    }

    @Test("家事削除時は家事を削除するAPIを実行する")
    func remove() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                    // Assert

                    let expected: HouseworkItem = .makeForTest(
                        id: inputHouseworkItem.id,
                        indexedDate: inputHouseworkItem.indexedDate.value,
                        title: inputHouseworkItem.title,
                        point: inputHouseworkItem.point,
                        state: .notTodo,
                        expiredAt: inputHouseworkItem.expiredAt
                    )
                    #expect(item == expected)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .previewValue,
                items: [.makeForTest(items: [inputHouseworkItem])]
            )

            // Act

            try await store.remove(
                target: inputHouseworkItem,
                cohabitantId: inputCohabitantId,
                isRegistered: true,
                step: .detail
            )
        }
    }

    @Test("テンプレートから生成された家事削除時は家事を削除するAPIを実行する")
    func remove_with_created_template() async throws {
        // Arrange

        let inputNow = Date(timeIntervalSince1970: 1000)
        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                    // Assert

                    let expected: HouseworkItem = .makeForTest(
                        id: inputHouseworkItem.id,
                        indexedDate: inputHouseworkItem.indexedDate.value,
                        title: inputHouseworkItem.title,
                        point: inputHouseworkItem.point,
                        state: .notTodo,
                        expiredAt: inputHouseworkItem.expiredAt,
                        createdAt: inputNow
                    )
                    #expect(item == expected)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .previewValue,
                now: { inputNow },
                items: []
            )

            // Act

            try await store.remove(
                target: inputHouseworkItem,
                cohabitantId: inputCohabitantId,
                isRegistered: false,
                step: .detail
            )
        }
    }

    @Test("コメント付きで初めてありがとうを伝えると、ありがとうを記録してパートナーに通知を送る")
    func sendThanks_firstWithComment_recordsAndNotifies() async {
        // Arrange

        let inputNow = Date(timeIntervalSince1970: 1000)
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let inputSender = Account(id: "senderId", userName: "おくりぬし", fcmToken: nil, cohabitantId: inputCohabitantId)
        let inputComment = "お疲れ様でした！"
        let expectedThanks = HouseworkThanks(comment: inputComment, sentAt: inputNow)
        let expectedNotificationContent = PushNotificationContent(
            message: .thanks(
                senderName: inputSender.userName,
                houseworkTitle: inputHouseworkItem.title,
                comment: inputComment
            ),
            thanksData: .init(houseworkId: inputHouseworkItem.id)
        )

        await confirmation(expectedCount: 2) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(
                        upsertThanksHandler: { houseworkId, senderId, thanks, cohabitantId in
                            // Assert

                            #expect(houseworkId == inputHouseworkItem.id)
                            #expect(senderId == inputSender.id)
                            #expect(thanks == expectedThanks)
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
                    try? await store.sendThanks(
                        target: inputHouseworkItem,
                        sender: inputSender,
                        comment: inputComment,
                        now: inputNow,
                        cohabitantId: inputCohabitantId,
                        step: .thanks
                    )
                }
            }
        }
    }

    @Test("コメントなしでありがとうを伝えると、ありがとうを記録し、通知は送らない")
    func sendThanks_withoutComment_recordsWithoutNotification() async throws {
        // Arrange

        let inputNow = Date(timeIntervalSince1970: 1000)
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let inputSender = Account(id: "senderId", userName: "おくりぬし", fcmToken: nil, cohabitantId: inputCohabitantId)
        let expectedThanks = HouseworkThanks(comment: nil, sentAt: inputNow)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    upsertThanksHandler: { _, _, thanks, _ in
                        // Assert

                        #expect(thanks == expectedThanks)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in
                    Issue.record()
                },
                items: [.makeForTest(items: [inputHouseworkItem])]
            )

            // Act

            try await store.sendThanks(
                target: inputHouseworkItem,
                sender: inputSender,
                comment: nil,
                now: inputNow,
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

    @Test("コメントなしで送ったありがとうにコメントを書き足すと、最初に送った日時のまま記録し、通知を送る")
    func sendThanks_addCommentToThanksWithoutComment_keepsSentAtAndNotifies() async {
        // Arrange

        let inputSentAt = Date(timeIntervalSince1970: 500)
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast,
            thanks: ["senderId": .init(comment: nil, sentAt: inputSentAt)]
        )
        let inputSender = Account(id: "senderId", userName: "おくりぬし", fcmToken: nil, cohabitantId: inputCohabitantId)
        let inputComment = "お疲れ様でした！"
        let expectedThanks = HouseworkThanks(comment: inputComment, sentAt: inputSentAt)
        let expectedNotificationContent = PushNotificationContent(
            message: .thanks(
                senderName: inputSender.userName,
                houseworkTitle: inputHouseworkItem.title,
                comment: inputComment
            ),
            thanksData: .init(houseworkId: inputHouseworkItem.id)
        )

        await confirmation(expectedCount: 2) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(
                        upsertThanksHandler: { _, _, thanks, _ in
                            // Assert

                            #expect(thanks == expectedThanks)
                            confirmation()
                        }
                    ),
                    cohabitantPushNotificationClient: .init { _, content in
                        // Assert

                        #expect(content == expectedNotificationContent)
                        confirmation()
                        continuation.resume()
                    },
                    items: [.makeForTest(items: [inputHouseworkItem])]
                )

                // Act

                Task {
                    try? await store.sendThanks(
                        target: inputHouseworkItem,
                        sender: inputSender,
                        comment: inputComment,
                        now: Date(timeIntervalSince1970: 1000),
                        cohabitantId: inputCohabitantId,
                        step: .thanks
                    )
                }
            }
        }
    }

    @Test("送ったコメントを直すと、最初に送った日時のまま記録し、通知は送らない")
    func sendThanks_editComment_keepsSentAtWithoutNotification() async throws {
        // Arrange

        let inputSentAt = Date(timeIntervalSince1970: 500)
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast,
            thanks: ["senderId": .init(comment: "ありがとう", sentAt: inputSentAt)]
        )
        let inputSender = Account(id: "senderId", userName: "おくりぬし", fcmToken: nil, cohabitantId: inputCohabitantId)
        let expectedThanks = HouseworkThanks(comment: "いつもありがとう", sentAt: inputSentAt)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    upsertThanksHandler: { _, _, thanks, _ in
                        // Assert

                        #expect(thanks == expectedThanks)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in
                    Issue.record()
                },
                items: [.makeForTest(items: [inputHouseworkItem])]
            )

            // Act

            try await store.sendThanks(
                target: inputHouseworkItem,
                sender: inputSender,
                comment: "いつもありがとう",
                now: Date(timeIntervalSince1970: 1000),
                cohabitantId: inputCohabitantId,
                step: .thanks
            )
        }
    }

    @Test("送信済みの家事にコメントなしのありがとうを送っても、記録を上書きせず通知も送らない")
    func sendThanks_withoutCommentToAlreadySent_doesNothing() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast,
            thanks: ["senderId": .init(comment: "ありがとう", sentAt: .distantPast)]
        )
        let inputSender = Account(id: "senderId", userName: "おくりぬし", fcmToken: nil, cohabitantId: inputCohabitantId)
        let store = HouseworkListStore(
            houseworkClient: .init(
                upsertThanksHandler: { _, _, _, _ in
                    // Assert

                    Issue.record()
                }
            ),
            cohabitantPushNotificationClient: .init { _, _ in
                // Assert

                Issue.record()
            },
            items: [.makeForTest(items: [inputHouseworkItem])]
        )

        // Act

        try await store.sendThanks(
            target: inputHouseworkItem,
            sender: inputSender,
            comment: nil,
            now: Date(timeIntervalSince1970: 1000),
            cohabitantId: inputCohabitantId,
            step: .board
        )
    }

    @Test("画面を開いている間に未完了へ戻された家事には、ありがとうを記録せず通知も送らない")
    func sendThanks_returnedToIncomplete_doesNothing() async throws {
        // Arrange

        let inputIndexedDate = Date(timeIntervalSince1970: 0)
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: inputIndexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let inputSender = Account(id: "senderId", userName: "おくりぬし", fcmToken: nil, cohabitantId: inputCohabitantId)
        let store = HouseworkListStore(
            houseworkClient: .init(
                upsertThanksHandler: { _, _, _, _ in
                    // Assert

                    Issue.record()
                }
            ),
            cohabitantPushNotificationClient: .init { _, _ in
                // Assert

                Issue.record()
            },
            items: [.makeForTest(items: [.makeForTest(id: 1, indexedDate: inputIndexedDate, state: .incomplete)])]
        )

        // Act

        try await store.sendThanks(
            target: inputHouseworkItem,
            sender: inputSender,
            comment: "お疲れ様でした！",
            now: Date(timeIntervalSince1970: 1000),
            cohabitantId: inputCohabitantId,
            step: .thanks
        )
    }

    @Test("ありがとうを記録できた後に通知の送信だけ失敗しても、失敗として返さない")
    func sendThanks_notificationFailed_doesNotThrow() async {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let inputSender = Account(id: "senderId", userName: "おくりぬし", fcmToken: nil, cohabitantId: inputCohabitantId)

        await confirmation(expectedCount: 2) { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkClient: .init(
                        upsertThanksHandler: { _, _, _, _ in
                            confirmation()
                        }
                    ),
                    cohabitantPushNotificationClient: .init { _, _ in
                        confirmation()
                        continuation.resume()
                        throw DomainError.other
                    },
                    items: [.makeForTest(items: [inputHouseworkItem])]
                )

                // Act & Assert

                Task {
                    do {
                        try await store.sendThanks(
                            target: inputHouseworkItem,
                            sender: inputSender,
                            comment: "お疲れ様でした！",
                            now: Date(timeIntervalSince1970: 1000),
                            cohabitantId: inputCohabitantId,
                            step: .thanks
                        )
                    } catch {
                        Issue.record("ありがとうの記録は成功として返るべき: \(error)")
                    }
                }
            }
        }
    }

    @Test(
        "まだありがとうを伝えていない家事に伝えると、初めて記録したとして返す",
        arguments: [nil, "お疲れ様でした！"]
    )
    func sendThanks_firstThanks_returnsTrue(comment: String?) async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let inputSender = Account(id: "senderId", userName: "おくりぬし", fcmToken: nil, cohabitantId: inputCohabitantId)
        let store = HouseworkListStore(
            houseworkClient: .init(upsertThanksHandler: { _, _, _, _ in }),
            cohabitantPushNotificationClient: .previewValue,
            items: [.makeForTest(items: [inputHouseworkItem])]
        )

        // Act

        let actual = try await store.sendThanks(
            target: inputHouseworkItem,
            sender: inputSender,
            comment: comment,
            now: Date(timeIntervalSince1970: 1000),
            cohabitantId: inputCohabitantId,
            step: .thanks
        )

        // Assert

        #expect(actual == true)
    }

    /// 初めてのありがとうにはならない送り方
    struct NotFirstThanksInput: CustomTestStringConvertible {

        let testDescription: String
        /// 送る時点の家事の状態
        let currentState: HouseworkState
        /// 送る時点ですでに送っていたありがとう
        let sentThanks: HouseworkThanks?
        let comment: String?

    }

    @Test(
        "すでに伝えた家事へのコメントの書き足し・編集や、記録しなかった場合は、初めて記録したとして返さない",
        arguments: [
            NotFirstThanksInput(
                testDescription: "コメントなしで送ったありがとうにコメントを書き足す",
                currentState: .completed,
                sentThanks: .init(comment: nil, sentAt: .distantPast),
                comment: "お疲れ様でした！"
            ),
            NotFirstThanksInput(
                testDescription: "送ったコメントを直す",
                currentState: .completed,
                sentThanks: .init(comment: "ありがとう", sentAt: .distantPast),
                comment: "いつもありがとう"
            ),
            NotFirstThanksInput(
                testDescription: "送信済みの家事にコメントなしで送る",
                currentState: .completed,
                sentThanks: .init(comment: "ありがとう", sentAt: .distantPast),
                comment: nil
            ),
            NotFirstThanksInput(
                testDescription: "未完了に戻された家事に送る",
                currentState: .incomplete,
                sentThanks: nil,
                comment: "お疲れ様でした！"
            ),
        ]
    )
    func sendThanks_notFirstThanks_returnsFalse(input: NotFirstThanksInput) async throws {
        // Arrange

        // 手元の家事とリスナーで受け取った家事を同じ家事として突き合わせるため、日付を揃える
        let inputIndexedDate = Date(timeIntervalSince1970: 0)
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: inputIndexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let currentHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: inputIndexedDate,
            state: input.currentState,
            executorId: "executorId",
            executedAt: .distantPast,
            thanks: input.sentThanks.map { ["senderId": $0] } ?? [:]
        )
        let inputSender = Account(id: "senderId", userName: "おくりぬし", fcmToken: nil, cohabitantId: inputCohabitantId)
        let store = HouseworkListStore(
            houseworkClient: .init(upsertThanksHandler: { _, _, _, _ in }),
            cohabitantPushNotificationClient: .previewValue,
            items: [.makeForTest(items: [currentHouseworkItem])]
        )

        // Act

        let actual = try await store.sendThanks(
            target: inputHouseworkItem,
            sender: inputSender,
            comment: input.comment,
            now: Date(timeIntervalSince1970: 1000),
            cohabitantId: inputCohabitantId,
            step: .thanks
        )

        // Assert

        #expect(actual == false)
    }

    @Test("家事のリスナーがエラーで終了すると、ロード状態が失敗になる")
    func startObserving_updatesLoadStateToFailed() async {
        // Arrange

        let (stream, streamContinuation) = AsyncThrowingStream<[HouseworkItem], Error>.makeStream()
        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in stream },
                fetchItemsHandler: { _, _, _ in [] }
            )
        )
        let store = HouseworkListStore(houseworkManager: manager)
        await manager.setupObserver(
            currentTime: Date(),
            cohabitantId: inputCohabitantId,
            calendar: .japanese,
            storagePolicy: .premium
        )

        // Act

        streamContinuation.finish(throwing: DomainError.noNetwork)

        // Assert

        // 失敗がManager経由でStoreに届くまで、各タスクに実行機会を与える
        for _ in 0 ..< 100 where store.loadState != .failed(.noNetwork) {
            await Task.yield()
        }
        #expect(store.loadState == .failed(.noNetwork))
    }

}

// MARK: - ふりかえり通知

extension HouseworkListStoreTest {

    @MainActor
    struct DailyCompletionReminderCase {

        private let inputCohabitantId = "cohabitantId"

    }

}

extension HouseworkListStoreTest.DailyCompletionReminderCase {

    @Test("今日完了した家事を受け取ると、今日のふりかえり通知を予約する")
    // swiftlint:disable:next function_body_length
    func startObserving_completedToday_schedulesReminder() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let inputItems = [
            HouseworkItem.makeForTest(
                id: 1,
                indexedDate: .previewDate(year: 2026, month: 9, day: 25),
                state: .completed
            ),
        ]
        let expected = DailyCompletionReminderRequest(
            identifier: "dailyCompletionReminder-2026-9-25",
            fireDateComponents: DateComponents(year: 2026, month: 9, day: 25, hour: 21, minute: 0)
        )
        // Storeの購読開始とフェッチの前後関係に依らず届くよう、リスナーからも同じ家事を流す
        let (stream, streamContinuation) = AsyncThrowingStream<[HouseworkItem], Error>.makeStream()
        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in stream },
                fetchItemsHandler: { _, _, _ in inputItems }
            )
        )

        await confirmation { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkManager: manager,
                    dailyCompletionReminderUseCase: .init(
                        client: .init(
                            loadSetting: { .init(isEnabled: true, hour: 21, minute: 0) },
                            schedule: { request in
                                // Assert

                                #expect(request == expected)
                                confirmation()
                                continuation.resume()
                            },
                            cancel: { _ in Issue.record() }
                        )
                    ),
                    calendar: .japanese,
                    now: { now }
                )

                // Act

                Task {
                    _ = store
                    await manager.setupObserver(
                        currentTime: now,
                        cohabitantId: inputCohabitantId,
                        calendar: .japanese,
                        storagePolicy: .premium
                    )
                    streamContinuation.yield(inputItems)
                }
            }
        }
        streamContinuation.finish()
    }

    @Test("今日完了した家事が無ければ、今日のふりかえり通知を取り消す")
    // swiftlint:disable:next function_body_length
    func startObserving_noCompletedToday_cancelsReminder() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 9, day: 25, hour: 10)
        let inputItems = [
            HouseworkItem.makeForTest(
                id: 1,
                indexedDate: .previewDate(year: 2026, month: 9, day: 25),
                state: .incomplete
            ),
            HouseworkItem.makeForTest(
                id: 2,
                indexedDate: .previewDate(year: 2026, month: 9, day: 24),
                state: .completed
            ),
        ]
        // Storeの購読開始とフェッチの前後関係に依らず届くよう、リスナーからも同じ家事を流す
        let (stream, streamContinuation) = AsyncThrowingStream<[HouseworkItem], Error>.makeStream()
        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in stream },
                fetchItemsHandler: { _, _, _ in inputItems }
            )
        )

        await confirmation { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    houseworkManager: manager,
                    dailyCompletionReminderUseCase: .init(
                        client: .init(
                            loadSetting: { .init(isEnabled: true, hour: 21, minute: 0) },
                            schedule: { _ in Issue.record() },
                            cancel: { identifier in
                                // Assert

                                #expect(identifier == "dailyCompletionReminder-2026-9-25")
                                confirmation()
                                continuation.resume()
                            }
                        )
                    ),
                    calendar: .japanese,
                    now: { now }
                )

                // Act

                Task {
                    _ = store
                    await manager.setupObserver(
                        currentTime: now,
                        cohabitantId: inputCohabitantId,
                        calendar: .japanese,
                        storagePolicy: .premium
                    )
                    streamContinuation.yield(inputItems)
                }
            }
        }
        streamContinuation.finish()
    }

}
