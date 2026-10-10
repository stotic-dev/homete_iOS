//
//  ThanksPromptSummaryTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct ThanksPromptSummaryTest {

    private let calendar = Calendar.japanese
    private let now = Date.previewDate(year: 2026, month: 10, day: 6, hour: 8)
    private let members = CohabitantMemberList(
        value: [
            .init(id: "own", userName: "たろう"),
            .init(id: "partnerA", userName: "はなこ"),
            .init(id: "partnerB", userName: "じろう"),
        ],
        ownId: "own"
    )

    @Test("同居人がいても、ありがとうを伝えられる家事がなければ促さない")
    func make_noThankableItems_returnsEmpty() {
        // Arrange
        let today = Date.previewDate(year: 2026, month: 10, day: 6)
        let storedAllItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [
                .makeForTest(id: 1, indexedDate: today, state: .completed, executorId: "own"),
                .makeForTest(id: 2, indexedDate: today, state: .incomplete),
            ]),
        ])

        // Act
        let actual = ThanksPromptSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            now: now,
            calendar: calendar
        )

        // Assert
        #expect(actual == .init(thankableItems: [], notSentCount: 0, executorNames: []))
    }

    @Test("今日と昨日に同居人が終えた家事を、未送信 → 送信済みの順、完了日時の新しい順に並べ、一昨日の家事は含めない")
    func make_thankableItems_returnsSortedItems() {
        // Arrange
        let sentItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .previewDate(year: 2026, month: 10, day: 6),
            state: .completed,
            executorId: "partnerA",
            executedAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7),
            thanks: ["own": .init(comment: nil, sentAt: .distantPast)]
        )
        let todayItem = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: .previewDate(year: 2026, month: 10, day: 6),
            state: .completed,
            executorId: "partnerA",
            executedAt: .previewDate(year: 2026, month: 10, day: 6, hour: 6)
        )
        let yesterdayItem = HouseworkItem.makeForTest(
            id: 3,
            indexedDate: .previewDate(year: 2026, month: 10, day: 5),
            state: .completed,
            executorId: "partnerA",
            executedAt: .previewDate(year: 2026, month: 10, day: 5, hour: 23)
        )
        let twoDaysAgoItem = HouseworkItem.makeForTest(
            id: 4,
            indexedDate: .previewDate(year: 2026, month: 10, day: 4),
            state: .completed,
            executorId: "partnerA"
        )
        let storedAllItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [sentItem, todayItem]),
            .makeForTest(items: [yesterdayItem]),
            .makeForTest(items: [twoDaysAgoItem]),
        ])

        // Act
        let actual = ThanksPromptSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = ThanksPromptSummary(
            thankableItems: [
                .init(originalItem: todayItem, isRegistered: true),
                .init(originalItem: yesterdayItem, isRegistered: true),
                .init(originalItem: sentItem, isRegistered: true),
            ],
            notSentCount: 2,
            executorNames: ["はなこ"]
        )
        #expect(actual == expected)
    }

    @Test("まだ送っていない家事の担当者だけを、自分を除いてメンバー一覧の順に並べる")
    func make_multipleExecutors_returnsNotSentExecutorNames() {
        // Arrange
        let today = Date.previewDate(year: 2026, month: 10, day: 6)
        let sharedItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: today,
            state: .completed,
            executors: [
                .init(userId: "own", percentage: 50, point: 50),
                .init(userId: "partnerB", percentage: 50, point: 50),
            ],
            executedAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)
        )
        let sentItem = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: today,
            state: .completed,
            executorId: "partnerA",
            executedAt: .previewDate(year: 2026, month: 10, day: 6, hour: 6),
            thanks: ["own": .init(comment: nil, sentAt: .distantPast)]
        )
        let storedAllItems = StoredAllHouseworkList(value: [.makeForTest(items: [sharedItem, sentItem])])

        // Act
        let actual = ThanksPromptSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = ThanksPromptSummary(
            thankableItems: [
                .init(originalItem: sharedItem, isRegistered: true),
                .init(originalItem: sentItem, isRegistered: true),
            ],
            notSentCount: 1,
            executorNames: ["じろう"]
        )
        #expect(actual == expected)
    }

}
