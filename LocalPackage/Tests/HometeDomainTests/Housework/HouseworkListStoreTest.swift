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

    @Test("新しい家事を登録すると保存だけを行い、パートナーには通知を送らない")
    func register() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                    // Assert

                    #expect(item == inputHouseworkItem)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() }
            )

            // Act

            try await store.register(newItem: inputHouseworkItem, cohabitantId: inputCohabitantId, step: .board)
        }
    }

    @Test("sendNotificationを実行すると、渡した内容がそのまま通知として送信される")
    func sendNotification() async {
        // Arrange

        let inputContent = PushNotificationContent(title: "3件の家事が完了しました", message: "確認してください")

        await confirmation { confirmation in
            let _: Void = await withCheckedContinuation { continuation in
                let store = HouseworkListStore(
                    cohabitantPushNotificationClient: .init { id, content in
                        // Assert

                        #expect(id == inputCohabitantId)
                        #expect(content == inputContent)
                        confirmation()
                        continuation.resume()
                    }
                )

                // Act

                store.sendNotification(inputContent, cohabitantId: inputCohabitantId)
            }
        }
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
            title: "じっこうしゃさんが家事を終えました",
            message: "「\(inputHouseworkItem.title)」が完了しました",
            data: ["type": "houseworkCompleted", "houseworkDate": "1790262000"]
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
            title: "じっこうしゃさんが家事を終えました",
            message: "「\(inputHouseworkItem.title)」が完了しました",
            data: ["type": "houseworkCompleted", "houseworkDate": "1790262000"]
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
                    items: []
                )

                // Act

                Task {
                    try await store.complete(
                        target: inputHouseworkItem,
                        now: completedAt,
                        reporter: inputExecutor,
                        executors: [.init(userId: inputExecutor.id, percentage: 100, point: inputHouseworkItem.point)],
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
            executedAt: completedAt,
            expiredAt: inputHouseworkItem.expiredAt,
            templateHouseworkItemId: nil
        )
        let expectedContent = PushNotificationContent(
            title: "きろくしゃさんが家事の完了を記録しました",
            message: "「title」（担当：きろくしゃさん・パートナーさん）\n一緒に片付けました",
            data: ["type": "houseworkCompleted", "houseworkDate": "1790262000"]
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
            templateHouseworkItemId: nil
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
            title: "じっこうしゃさんが家事を終えました",
            message: "「\(inputHouseworkItem.title)」が完了しました",
            data: ["type": "houseworkCompleted", "houseworkDate": "1790262000"]
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

    @Test("完了した家事にありがとうを伝えると、パートナーに通知を送信する")
    func sendThanks() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let inputSender = Account(
            id: "senderId",
            userName: "おくりぬし",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let inputComment = "お疲れ様でした！"
        let expectedNotificationContent = PushNotificationContent(
            title: "\(inputSender.userName)さんから「\(inputHouseworkItem.title)」にありがとうが届きました",
            message: inputComment
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { _, _ in
                        // ありがとうは家事のステータスを変えないため、保存は行われない
                        Issue.record()
                    }
                ),
                cohabitantPushNotificationClient: .init { id, content in
                    // Assert

                    #expect(id == inputCohabitantId)
                    #expect(content == expectedNotificationContent)
                    confirmation()
                },
                items: [.makeForTest(items: [inputHouseworkItem])]
            )

            // Act

            try await store.sendThanks(
                target: inputHouseworkItem,
                sender: inputSender,
                comment: inputComment,
                cohabitantId: inputCohabitantId,
                step: .thanks
            )
        }
    }

    @Test("一括操作でありがとうを伝えるときは、家事ごとの個別通知を送らない")
    func sendThanks_withoutNotify() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let inputSender = Account(
            id: "senderId",
            userName: "おくりぬし",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let store = HouseworkListStore(
            houseworkClient: .init(
                insertOrUpdateItemHandler: { _, _ in
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
            comment: "ありがとう！",
            cohabitantId: inputCohabitantId,
            step: .board,
            notify: false
        )
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
            fireDateComponents: DateComponents(year: 2026, month: 9, day: 25, hour: 21, minute: 0),
            title: "今日もおつかれさまでした",
            body: "今日完了した家事があります。ふりかえって、感謝を伝え合いましょう"
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
