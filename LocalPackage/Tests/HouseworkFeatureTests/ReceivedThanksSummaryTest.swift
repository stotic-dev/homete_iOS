//
//  ReceivedThanksSummaryTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct ReceivedThanksSummaryTest {

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

    @Test("自分が終えた家事にありがとうが届いていなければ、伝えない")
    func make_noThanks_returnsEmpty() {
        // Arrange
        let storedAllItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [
                .makeForTest(id: 1, state: .completed, executorId: "own"),
                // 同居人が終えた家事に自分が送ったありがとうは、届いたものではない
                .makeForTest(
                    id: 2,
                    state: .completed,
                    executorId: "partnerA",
                    thanks: ["own": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7))]
                ),
            ]),
        ])

        // Act
        let actual = ReceivedThanksSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            seenUntil: nil,
            now: now,
            calendar: calendar
        )

        // Assert
        #expect(actual == .init(count: 0, senderNames: [], latestSentAt: nil))
    }

    @Test("今日と昨日に届いたありがとうを送った人ごとに数え、一昨日に届いたものは含めない")
    func make_receivedThanks_countsThanksSinceYesterday() {
        // Arrange
        let todayItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "own",
            thanks: [
                "partnerA": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)),
                "partnerB": .init(comment: "助かったよ", sentAt: .previewDate(year: 2026, month: 10, day: 5, hour: 23)),
            ]
        )
        let twoDaysAgoItem = HouseworkItem.makeForTest(
            id: 2,
            state: .completed,
            executorId: "own",
            thanks: ["partnerB": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 10, day: 4, hour: 23))]
        )
        let storedAllItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [todayItem]),
            .makeForTest(items: [twoDaysAgoItem]),
        ])

        // Act
        let actual = ReceivedThanksSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            seenUntil: nil,
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = ReceivedThanksSummary(
            count: 2,
            senderNames: ["はなこ", "じろう"],
            latestSentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)
        )
        #expect(actual == expected)
    }

    @Test("複数人で終えた家事では自分に届いたものとして数え、グループを抜けた人の名前は出さない")
    func make_sharedItemAndLeftMember_countsWithoutLeftMemberName() {
        // Arrange
        let sharedItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executors: [
                .init(userId: "own", percentage: 50, point: 50),
                .init(userId: "partnerB", percentage: 50, point: 50),
            ],
            thanks: ["partnerA": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7))]
        )
        let leftMemberItem = HouseworkItem.makeForTest(
            id: 2,
            state: .completed,
            executorId: "own",
            thanks: ["leftMember": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 6))]
        )
        let storedAllItems = StoredAllHouseworkList(value: [.makeForTest(items: [sharedItem, leftMemberItem])])

        // Act
        let actual = ReceivedThanksSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            seenUntil: nil,
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = ReceivedThanksSummary(
            count: 2,
            senderNames: ["はなこ"],
            latestSentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)
        )
        #expect(actual == expected)
    }

    @Test("前に見た日時までに届いたありがとうは数えず、その後に届いたものだけを数える")
    func make_seenUntil_countsOnlyThanksAfterSeen() {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "own",
            thanks: [
                "partnerA": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 6)),
                "partnerB": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)),
            ]
        )
        let storedAllItems = StoredAllHouseworkList(value: [.makeForTest(items: [item])])

        // Act
        let actual = ReceivedThanksSummary.make(
            storedAllItems: storedAllItems,
            members: members,
            ownUserId: "own",
            seenUntil: .previewDate(year: 2026, month: 10, day: 6, hour: 6),
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = ReceivedThanksSummary(
            count: 1,
            senderNames: ["じろう"],
            latestSentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)
        )
        #expect(actual == expected)
    }

}
