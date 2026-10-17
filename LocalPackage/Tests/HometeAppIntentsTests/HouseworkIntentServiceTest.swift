// swiftlint:disable file_length
//
//  HouseworkIntentServiceTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeAppIntents
import HometeDomain
import Testing

struct HouseworkIntentServiceTest {

    private let now = Date.previewDate(year: 2026, month: 10, day: 12, hour: 9)
    private let today = Date.previewDate(year: 2026, month: 10, day: 12)
    private let expiredAt = Date.previewDate(year: 2027, month: 10, day: 12)
    private let createdAt = Date.previewDate(year: 2026, month: 10, day: 11)
    private let own = Account(id: "own", userName: "たろう", fcmToken: nil, cohabitantId: "cohabitant")
    private let partner = Account(id: "partner", userName: "はなこ", fcmToken: nil, cohabitantId: "cohabitant")

}

// MARK: - 家事の完了

extension HouseworkIntentServiceTest {

    @Test("今日の未完了の家事に同じ名前があれば、自分だけを担当者にして「ふつう」で完了にする")
    func completeHousework() async throws {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(
            id: "laundry",
            indexedDate: today,
            title: "洗濯",
            point: 20,
            expiredAt: expiredAt,
            createdAt: createdAt
        )
        let expectedItem = HouseworkItem.makeForTest(
            id: "laundry",
            indexedDate: today,
            title: "洗濯",
            point: 20,
            state: .completed,
            executorId: "own",
            effort: .normal,
            executedAt: now,
            expiredAt: expiredAt,
            createdAt: createdAt
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [inputItem],
                houseworkClient: { fetchItems in
                    .init(
                        insertOrUpdateItemHandler: { item, cohabitantId in
                            // Assert

                            #expect(item == expectedItem)
                            #expect(cohabitantId == "cohabitant")
                            confirmation()
                        },
                        fetchItemsHandler: fetchItems
                    )
                }
            )
            return try await sut.completeHousework(title: "洗濯", now: now)
        }

        // Assert

        #expect(actual == .completed(point: 20))
    }

    @Test("今日の家事に同じ名前の家事が無い場合は、何も書き込まずnotFoundを返す")
    func completeHouseworkNotFound() async throws {
        // Arrange

        let sut = makeSUT(
            items: [.makeForTest(id: "dish", indexedDate: today, title: "皿洗い", expiredAt: expiredAt)],
            houseworkClient: { fetchItems in
                .init(
                    insertOrUpdateItemHandler: { _, _ in Issue.record("書き込まない") },
                    fetchItemsHandler: fetchItems
                )
            }
        )

        // Act

        let actual = try await sut.completeHousework(title: "洗濯", now: now)

        // Assert

        #expect(actual == .notFound)
    }

    @Test("同じ名前の家事が今日はもう終わっている場合は、何も書き込まずalreadyCompletedを返す")
    func completeHouseworkAlreadyCompleted() async throws {
        // Arrange

        let sut = makeSUT(
            items: [
                .makeForTest(
                    id: "laundry",
                    indexedDate: today,
                    title: "洗濯",
                    state: .completed,
                    executorId: "partner",
                    executedAt: now,
                    expiredAt: expiredAt
                ),
            ],
            houseworkClient: { fetchItems in
                .init(
                    insertOrUpdateItemHandler: { _, _ in Issue.record("書き込まない") },
                    fetchItemsHandler: fetchItems
                )
            }
        )

        // Act

        let actual = try await sut.completeHousework(title: "洗濯", now: now)

        // Assert

        #expect(actual == .alreadyCompleted)
    }

    @Test("テンプレートから出している未登録の家事なら、テンプレートの家事と日付から決まるIDで新しく作って完了にする")
    func completeHouseworkFromTemplate() async throws {
        // Arrange

        let templateItemId = HouseworkTemplateItem.ItemId(id: "laundry")
        let expectedItem = HouseworkItem.makeForTest(
            id: "template-laundry-20261012",
            indexedDate: today,
            title: "洗濯",
            point: 30,
            state: .completed,
            executorId: "own",
            effort: .normal,
            executedAt: now,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateItemId,
            createdAt: now
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [],
                houseworkClient: { fetchItems in
                    .init(
                        insertOrUpdateItemHandler: { item, _ in
                            // Assert

                            #expect(item == expectedItem)
                            confirmation()
                        },
                        fetchItemsHandler: fetchItems
                    )
                },
                houseworkTemplateClient: .init(
                    fetchTemplates: { _ in [.init(templateId: "template", name: "いつもの家事")] },
                    fetchDays: { _, _ in
                        // 2026/10/12は月曜日
                        [.init(dayOfWeek: .monday, items: [
                            .init(id: templateItemId, title: "洗濯", point: 30, updatedAt: createdAt),
                        ])]
                    },
                    fetchMonthlyItems: { _, _ in [] }
                )
            )
            return try await sut.completeHousework(title: "洗濯", now: now)
        }

        // Assert

        #expect(actual == .completed(point: 30))
    }

    @Test("同じ名前の未完了の家事が複数あるときは、ダッシュボードと同じ並び（ポイントの高い順）の先頭を完了にする")
    func completeHouseworkSameTitle() async throws {
        // Arrange

        let expectedItem = HouseworkItem.makeForTest(
            id: "laundry2",
            indexedDate: today,
            title: "洗濯",
            point: 30,
            state: .completed,
            executorId: "own",
            effort: .normal,
            executedAt: now,
            expiredAt: expiredAt,
            createdAt: createdAt
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [
                    .makeForTest(
                        id: "laundry1",
                        indexedDate: today,
                        title: "洗濯",
                        point: 10,
                        expiredAt: expiredAt,
                        createdAt: createdAt
                    ),
                    .makeForTest(
                        id: "laundry2",
                        indexedDate: today,
                        title: "洗濯",
                        point: 30,
                        expiredAt: expiredAt,
                        createdAt: createdAt
                    ),
                ],
                houseworkClient: { fetchItems in
                    .init(
                        insertOrUpdateItemHandler: { item, _ in
                            // Assert

                            #expect(item == expectedItem)
                            confirmation()
                        },
                        fetchItemsHandler: fetchItems
                    )
                }
            )
            return try await sut.completeHousework(title: "洗濯", now: now)
        }

        // Assert

        #expect(actual == .completed(point: 30))
    }

    @Test("完了にしたら、返す前に同居人への完了通知を送り終え、今日のふりかえり通知を予約する")
    func completeHouseworkNotifiesBeforeReturning() async throws {
        // Arrange

        let expectedContent = PushNotificationContent(
            message: .completed(executorName: "たろう", houseworkTitle: "洗濯", comment: ""),
            completedData: .init(houseworkDate: today)
        )
        let expectedRequest = DailyCompletionReminderRequest(
            identifier: "dailyCompletionReminder-2026-10-12",
            fireDateComponents: DateComponents(year: 2026, month: 10, day: 12, hour: 21, minute: 0)
        )

        // Act

        _ = try await confirmation(expectedCount: 2) { confirmation in
            let sut = makeSUT(
                items: [.makeForTest(id: "laundry", indexedDate: today, title: "洗濯", expiredAt: expiredAt)],
                houseworkClient: { fetchItems in
                    .init(insertOrUpdateItemHandler: { _, _ in }, fetchItemsHandler: fetchItems)
                },
                pushNotificationClient: .init { _, content in
                    // Assert

                    #expect(content == expectedContent)
                    confirmation()
                },
                reminderClient: .init(schedule: { request in
                    // Assert

                    #expect(request == expectedRequest)
                    confirmation()
                })
            )
            // 送信を待たずに返すと、confirmationを抜けた後に通知が送られて数に入らない
            return try await sut.completeHousework(title: "洗濯", now: now)
        }
    }

}

// MARK: - ありがとう

extension HouseworkIntentServiceTest {

    @Test("同居人が終えた家事のうち、まだありがとうを送っていないものを、担当した人の名前と一緒に返す")
    func thanksCandidates() async throws {
        // Arrange

        let notSentItem = HouseworkItem.makeForTest(
            id: "dish",
            indexedDate: today,
            title: "皿洗い",
            state: .completed,
            executorId: "partner",
            executedAt: now,
            expiredAt: expiredAt
        )
        let sut = makeSUT(
            items: [
                notSentItem,
                .makeForTest(
                    id: "laundry",
                    indexedDate: today,
                    title: "洗濯",
                    state: .completed,
                    executorId: "partner",
                    executedAt: now,
                    expiredAt: expiredAt,
                    thanks: ["own": .init(comment: nil, sentAt: now)]
                ),
                .makeForTest(
                    id: "bath",
                    indexedDate: today,
                    title: "お風呂掃除",
                    state: .completed,
                    executorId: "own",
                    executedAt: now,
                    expiredAt: expiredAt
                ),
            ]
        )
        let expected = [ThanksCandidate(item: notSentItem, executorNames: ["はなこ"])]

        // Act

        let actual = try await sut.thanksCandidates(now: now)

        // Assert

        #expect(actual == expected)
    }

    @Test("昨日の家事は候補に含め、一昨日の家事は含めない")
    func thanksCandidatesDateBoundary() async throws {
        // Arrange

        let yesterdayItem = HouseworkItem.makeForTest(
            id: "dish",
            indexedDate: .previewDate(year: 2026, month: 10, day: 11),
            title: "皿洗い",
            state: .completed,
            executorId: "partner",
            executedAt: .previewDate(year: 2026, month: 10, day: 11, hour: 23),
            expiredAt: expiredAt
        )
        let sut = makeSUT(
            items: [
                yesterdayItem,
                .makeForTest(
                    id: "laundry",
                    indexedDate: .previewDate(year: 2026, month: 10, day: 10),
                    title: "洗濯",
                    state: .completed,
                    executorId: "partner",
                    executedAt: .previewDate(year: 2026, month: 10, day: 10, hour: 20),
                    expiredAt: expiredAt
                ),
            ]
        )
        let expected = [ThanksCandidate(item: yesterdayItem, executorNames: ["はなこ"])]

        // Act

        let actual = try await sut.thanksCandidates(now: now)

        // Assert

        #expect(actual == expected)
    }

    @Test("ありがとうを伝えられる家事なら、コメントを添えて記録し、相手に通知する")
    func sendThanks() async throws {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(
            id: "dish",
            indexedDate: today,
            title: "皿洗い",
            state: .completed,
            executorId: "partner",
            executedAt: now,
            expiredAt: expiredAt
        )
        let expectedContent = PushNotificationContent.thanksMessage(
            senderName: "たろう",
            houseworkTitle: "皿洗い",
            houseworkId: "dish",
            comment: "助かった"
        )

        // Act

        let actual = try await confirmation(expectedCount: 2) { confirmation in
            let sut = makeSUT(
                items: [inputItem],
                houseworkClient: { fetchItems in
                    .init(
                        upsertThanksHandler: { houseworkId, senderId, thanks, cohabitantId in
                            // Assert

                            #expect(houseworkId == "dish")
                            #expect(senderId == "own")
                            #expect(thanks == HouseworkThanks(comment: "助かった", sentAt: now))
                            #expect(cohabitantId == "cohabitant")
                            confirmation()
                        },
                        fetchItemsHandler: fetchItems
                    )
                },
                pushNotificationClient: .init { cohabitantId, content in
                    // Assert

                    #expect(cohabitantId == "cohabitant")
                    #expect(content == expectedContent)
                    confirmation()
                }
            )
            return try await sut.sendThanks(houseworkId: "dish", comment: " 助かった ", now: now)
        }

        // Assert

        #expect(actual == .sent(houseworkTitle: "皿洗い"))
    }

    @Test("コメントが空白だけなら、コメントなしで記録し、相手に通知しない")
    func sendThanksBlankComment() async throws {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(
            id: "dish",
            indexedDate: today,
            title: "皿洗い",
            state: .completed,
            executorId: "partner",
            executedAt: now,
            expiredAt: expiredAt
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [inputItem],
                houseworkClient: { fetchItems in
                    .init(
                        upsertThanksHandler: { _, _, thanks, _ in
                            // Assert

                            #expect(thanks == HouseworkThanks(comment: nil, sentAt: now))
                            confirmation()
                        },
                        fetchItemsHandler: fetchItems
                    )
                },
                pushNotificationClient: .init { _, _ in Issue.record("通知しない") }
            )
            return try await sut.sendThanks(houseworkId: "dish", comment: "  \n ", now: now)
        }

        // Assert

        #expect(actual == .sent(houseworkTitle: "皿洗い"))
    }

    @Test("すでにありがとうを送っていた家事には、コメントの編集もせずnotFoundを返す")
    func sendThanksAlreadySent() async throws {
        // Arrange

        let sut = makeSUT(
            items: [
                .makeForTest(
                    id: "dish",
                    indexedDate: today,
                    title: "皿洗い",
                    state: .completed,
                    executorId: "partner",
                    executedAt: now,
                    expiredAt: expiredAt,
                    thanks: ["own": .init(comment: nil, sentAt: now)]
                ),
            ],
            houseworkClient: { fetchItems in
                .init(
                    upsertThanksHandler: { _, _, _, _ in Issue.record("書き込まない") },
                    fetchItemsHandler: fetchItems
                )
            }
        )

        // Act

        let actual = try await sut.sendThanks(houseworkId: "dish", comment: "助かった", now: now)

        // Assert

        #expect(actual == .notFound)
    }

}

// MARK: - 通信できないとき

extension HouseworkIntentServiceTest {

    @Test("完了の書き込みがサーバーに届くのを待ちきれなければ、オンラインになったら反映されることを返す")
    func completeHouseworkPendingSync() async throws {
        // Arrange

        var sut = makeSUT(
            items: [.makeForTest(id: "laundry", indexedDate: today, title: "洗濯", expiredAt: expiredAt)],
            houseworkClient: { fetchItems in
                .init(
                    // オフラインのFirestoreのように、サーバーの応答まで返らない
                    insertOrUpdateItemHandler: { _, _ in try await Task.sleep(for: .seconds(60)) },
                    fetchItemsHandler: fetchItems
                )
            }
        )
        sut.writeTimeout = .milliseconds(10)

        // Act

        let actual = try await sut.completeHousework(title: "洗濯", now: now)

        // Assert

        #expect(actual == .pendingSync)
    }

    @Test("ありがとうの書き込みがサーバーに届くのを待ちきれなければ、オンラインになったら届くことを返す")
    func sendThanksPendingSync() async throws {
        // Arrange

        var sut = makeSUT(
            items: [
                .makeForTest(
                    id: "dish",
                    indexedDate: today,
                    title: "皿洗い",
                    state: .completed,
                    executorId: "partner",
                    executedAt: now,
                    expiredAt: expiredAt
                ),
            ],
            houseworkClient: { fetchItems in
                .init(
                    // オフラインのFirestoreのように、サーバーの応答まで返らない
                    upsertThanksHandler: { _, _, _, _ in try await Task.sleep(for: .seconds(60)) },
                    fetchItemsHandler: fetchItems
                )
            }
        )
        sut.writeTimeout = .milliseconds(10)

        // Act

        let actual = try await sut.sendThanks(houseworkId: "dish", comment: nil, now: now)

        // Assert

        #expect(actual == .pendingSync(houseworkTitle: "皿洗い"))
    }

}

private extension HouseworkIntentServiceTest {

    typealias FetchItems = @Sendable (String, Date, Date) async throws -> [HouseworkItem]

    func makeSUT(
        items: [HouseworkItem],
        houseworkClient: (_ fetchItems: @escaping FetchItems) -> HouseworkClient = { .init(fetchItemsHandler: $0) },
        houseworkTemplateClient: HouseworkTemplateClient = .init(),
        pushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        reminderClient: DailyCompletionReminderClient = .previewValue
    ) -> HouseworkIntentService {
        let accounts = [own.id: own, partner.id: partner]
        let houseworkClient = houseworkClient { _, _, _ in items }
        let analyticsClient = AnalyticsClient.previewValue
        let reminderUseCase = DailyCompletionReminderUseCase(client: reminderClient)
        return .init(
            sessionUseCase: .init(
                accountAuthClient: .init(currentAuth: { .init(id: "own") }),
                accountInfoClient: .init(fetch: { accounts[$0] }),
                cohabitantClient: .init(addSnapshotListener: { _, _ in
                    AsyncThrowingStream { $0.yield(CohabitantData(id: "cohabitant", members: ["own", "partner"])) }
                }),
                houseworkClient: houseworkClient,
                houseworkTemplateClient: houseworkTemplateClient,
                remoteConfigClient: .init(),
                currentAppVersion: "1.0.0"
            ),
            commandUseCase: .init(
                houseworkClient: houseworkClient,
                cohabitantPushNotificationClient: pushNotificationClient,
                analyticsClient: analyticsClient,
                dailyCompletionReminderUseCase: reminderUseCase,
                calendar: .japanese
            ),
            dailyCompletionReminderUseCase: reminderUseCase,
            calendar: .japanese
        )
    }

}
