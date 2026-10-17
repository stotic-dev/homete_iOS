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

    // MARK: - 家事の完了

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

    // MARK: - ありがとう

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

private extension HouseworkIntentServiceTest {

    typealias FetchItems = @Sendable (String, Date, Date) async throws -> [HouseworkItem]

    func makeSUT(
        items: [HouseworkItem],
        houseworkClient: (_ fetchItems: @escaping FetchItems) -> HouseworkClient = { .init(fetchItemsHandler: $0) },
        pushNotificationClient: CohabitantPushNotificationClient = .previewValue
    ) -> HouseworkIntentService {
        let accounts = [own.id: own, partner.id: partner]
        let houseworkClient = houseworkClient { _, _, _ in items }
        let analyticsClient = AnalyticsClient.previewValue
        let reminderUseCase = DailyCompletionReminderUseCase(client: .previewValue)
        return .init(
            sessionUseCase: .init(
                accountAuthClient: .init(currentAuth: { .init(id: "own") }),
                accountInfoClient: .init(fetch: { accounts[$0] }),
                cohabitantClient: .init(addSnapshotListener: { _, _ in
                    AsyncThrowingStream { $0.yield(CohabitantData(id: "cohabitant", members: ["own", "partner"])) }
                }),
                houseworkClient: houseworkClient,
                houseworkTemplateClient: .init(),
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
