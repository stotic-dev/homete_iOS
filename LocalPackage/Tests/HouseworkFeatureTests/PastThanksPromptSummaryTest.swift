//
//  PastThanksPromptSummaryTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct PastThanksPromptSummaryTest {

    private let calendar = Calendar.japanese
    private let now = Date.previewDate(year: 2026, month: 10, day: 10, hour: 8)
    private let members = CohabitantMemberList(
        value: [
            .init(id: "own", userName: "たろう"),
            .init(id: "partnerA", userName: "はなこ"),
            .init(id: "partnerB", userName: "じろう"),
        ],
        ownId: "own"
    )

    @Test("昨日から7日前までの未送信の家事を、日付の新しい順に日ごとに分け、今日・8日前・送信済みの家事は含めない")
    func make_pastItems_returnsDailyNotSentItems() {
        // Arrange
        let todayItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .previewDate(year: 2026, month: 10, day: 10),
            state: .completed,
            executorId: "partnerA"
        )
        let yesterdayItem = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: .previewDate(year: 2026, month: 10, day: 9),
            state: .completed,
            executorId: "partnerA",
            executedAt: .previewDate(year: 2026, month: 10, day: 9, hour: 23, minute: 50)
        )
        let yesterdaySentItem = HouseworkItem.makeForTest(
            id: 3,
            indexedDate: .previewDate(year: 2026, month: 10, day: 9),
            state: .completed,
            executorId: "partnerA",
            thanks: ["own": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 10, day: 9, hour: 22))]
        )
        let sevenDaysAgoItem = HouseworkItem.makeForTest(
            id: 4,
            indexedDate: .previewDate(year: 2026, month: 10, day: 3),
            state: .completed,
            executorId: "partnerB",
            executedAt: .previewDate(year: 2026, month: 10, day: 3, hour: 9)
        )
        let eightDaysAgoItem = HouseworkItem.makeForTest(
            id: 5,
            indexedDate: .previewDate(year: 2026, month: 10, day: 2),
            state: .completed,
            executorId: "partnerA"
        )
        let storedAllItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [todayItem]),
            .makeForTest(items: [yesterdayItem, yesterdaySentItem]),
            .makeForTest(items: [sevenDaysAgoItem]),
            .makeForTest(items: [eightDaysAgoItem]),
        ])

        // Act
        let actual = PastThanksPromptSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = PastThanksPromptSummary(
            dailyItems: [
                .init(
                    date: .previewDate(year: 2026, month: 10, day: 9),
                    items: [.init(originalItem: yesterdayItem, isRegistered: true)]
                ),
                .init(
                    date: .previewDate(year: 2026, month: 10, day: 3),
                    items: [.init(originalItem: sevenDaysAgoItem, isRegistered: true)]
                ),
            ],
            notSentCount: 2,
            executorNames: ["はなこ", "じろう"]
        )
        #expect(actual == expected)
    }

    @Test("一覧を開いた後に送った家事は送信済みとして残し、開く前に送った家事は含めない。どちらも件数には数えない")
    func make_keepingSentSince_keepsItemsSentAfterOpening() {
        // Arrange
        let openedAt = Date.previewDate(year: 2026, month: 10, day: 10, hour: 7)
        let notSentItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .previewDate(year: 2026, month: 10, day: 8),
            state: .completed,
            executorId: "partnerA",
            executedAt: .previewDate(year: 2026, month: 10, day: 8, hour: 9)
        )
        let sentAfterOpeningItem = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: .previewDate(year: 2026, month: 10, day: 8),
            state: .completed,
            executorId: "partnerA",
            executedAt: .previewDate(year: 2026, month: 10, day: 8, hour: 10),
            thanks: ["own": .init(comment: nil, sentAt: openedAt)]
        )
        let sentBeforeOpeningItem = HouseworkItem.makeForTest(
            id: 3,
            indexedDate: .previewDate(year: 2026, month: 10, day: 8),
            state: .completed,
            executorId: "partnerA",
            thanks: ["own": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 10, day: 10, hour: 6))]
        )
        let storedAllItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [notSentItem, sentAfterOpeningItem, sentBeforeOpeningItem]),
        ])

        // Act
        let actual = PastThanksPromptSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            now: now,
            calendar: calendar,
            keepingSentSince: openedAt
        )

        // Assert
        let expected = PastThanksPromptSummary(
            dailyItems: [
                .init(
                    date: .previewDate(year: 2026, month: 10, day: 8),
                    items: [
                        .init(originalItem: notSentItem, isRegistered: true),
                        .init(originalItem: sentAfterOpeningItem, isRegistered: true),
                    ]
                ),
            ],
            notSentCount: 1,
            executorNames: ["はなこ"]
        )
        #expect(actual == expected)
    }

    @Test(
        "日付が変わると、前の日の家事が過去側に移る",
        arguments: [
            (Date.previewDate(year: 2026, month: 10, day: 9, hour: 23, minute: 59), false),
            (Date.previewDate(year: 2026, month: 10, day: 10, hour: 0, minute: 1), true),
        ]
    )
    func make_dayChanged_movesItemToPast(now: Date, isPast: Bool) {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .previewDate(year: 2026, month: 10, day: 9),
            state: .completed,
            executorId: "partnerA",
            executedAt: .previewDate(year: 2026, month: 10, day: 9, hour: 23, minute: 50)
        )
        let storedAllItems = StoredAllHouseworkList(value: [.makeForTest(items: [item])])

        // Act
        let actual = PastThanksPromptSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = isPast
            ? PastThanksPromptSummary(
                dailyItems: [
                    .init(
                        date: .previewDate(year: 2026, month: 10, day: 9),
                        items: [.init(originalItem: item, isRegistered: true)]
                    ),
                ],
                notSentCount: 1,
                executorNames: ["はなこ"]
            )
            : PastThanksPromptSummary(dailyItems: [], notSentCount: 0, executorNames: [])
        #expect(actual == expected)
    }

}
