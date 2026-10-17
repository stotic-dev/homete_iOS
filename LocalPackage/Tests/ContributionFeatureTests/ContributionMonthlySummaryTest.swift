//
//  ContributionMonthlySummaryTest.swift
//  LocalPackage
//

@testable import ContributionFeature
import Foundation
import HometeDomain
import Testing

struct ContributionMonthlySummaryTest {

    @Test("指定した月に完了した家事だけを集計し、家事をしていないメンバーも0ptで並べる")
    func make() {
        // Arrange

        let month = Date.previewDate(year: 2026, month: 10, day: 12, hour: 9)
        let items = [
            HouseworkItem.makeForTest(
                id: "laundry",
                indexedDate: .previewDate(year: 2026, month: 10, day: 1),
                point: 20,
                state: .completed,
                executorId: "own",
                executedAt: .previewDate(year: 2026, month: 10, day: 1, hour: 9)
            ),
            HouseworkItem.makeForTest(
                id: "bath",
                indexedDate: .previewDate(year: 2026, month: 9, day: 30),
                point: 50,
                state: .completed,
                executorId: "own",
                executedAt: .previewDate(year: 2026, month: 9, day: 30, hour: 21)
            ),
        ]
        let members = CohabitantMemberList(
            value: [.init(id: "own", userName: "たろう"), .init(id: "partner", userName: "はなこ")],
            ownId: "own"
        )
        let expected = ContributionMonthlySummary(
            month: month,
            pointSummary: .init(items: [
                UserPointSummary(
                    userId: "own",
                    userName: "たろう",
                    isMe: true,
                    monthlyPoint: .init(value: 20),
                    achievedCount: 1
                ),
                UserPointSummary(
                    userId: "partner",
                    userName: "はなこ",
                    isMe: false,
                    monthlyPoint: .init(value: 0),
                    achievedCount: 0
                ),
            ])
        )

        // Act

        let actual = ContributionMonthlySummary.make(
            items: items,
            members: members,
            month: month,
            myUserId: "own",
            calendar: .japanese
        )

        // Assert

        #expect(actual == expected)
    }

}
