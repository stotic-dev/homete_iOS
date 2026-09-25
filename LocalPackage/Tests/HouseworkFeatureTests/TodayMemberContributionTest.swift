//
//  TodayMemberContributionTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2026/09/26.
//

import HometeDomain
@testable import HouseworkFeature
import Testing

struct TodayMemberContributionTest {

    static let members = CohabitantMemberList(
        value: [
            .init(id: "ownUserId", userName: "自分"),
            .init(id: "otherUserId", userName: "同居人"),
        ],
        ownId: "ownUserId"
    )

    @Test("完了した家事を実行者ごとに件数・ポイントで集計し、自分を先頭に並べる")
    func aggregatesCompletedItemsByExecutor() {
        // Arrange

        let summary = TodayHouseworkSummary.makeForTest(allItems: [
            .makeForTest(id: 1, point: 10, state: .completed, executorId: "otherUserId"),
            .makeForTest(id: 2, point: 20, state: .completed, executorId: "ownUserId"),
            .makeForTest(id: 3, point: 30, state: .completed, executorId: "otherUserId"),
        ])

        // Act

        let actual = summary.memberContributions(members: Self.members)

        // Assert

        let expected: [TodayMemberContribution] = [
            .init(userId: "ownUserId", userName: "自分", completedCount: 1, point: 20),
            .init(userId: "otherUserId", userName: "同居人", completedCount: 2, point: 40),
        ]
        #expect(actual == expected)
    }

    @Test("未完了・承認待ちの家事は集計に含めない")
    func excludesIncompleteAndPendingApprovalItems() {
        // Arrange

        let summary = TodayHouseworkSummary.makeForTest(allItems: [
            .makeForTest(id: 1, point: 10, state: .completed, executorId: "ownUserId"),
            .makeForTest(id: 2, point: 20, state: .pendingApproval, executorId: "ownUserId"),
            .makeForTest(id: 3, point: 30, state: .incomplete),
        ])

        // Act

        let actual = summary.memberContributions(members: Self.members)

        // Assert

        let expected: [TodayMemberContribution] = [
            .init(userId: "ownUserId", userName: "自分", completedCount: 1, point: 10),
            .init(userId: "otherUserId", userName: "同居人", completedCount: 0, point: 0),
        ]
        #expect(actual == expected)
    }

    @Test("完了した家事が無い場合も、全メンバーを0件・0ptで返す")
    func includesMembersWithoutCompletedItems() {
        // Arrange

        let summary = TodayHouseworkSummary.makeForTest(allItems: [
            .makeForTest(id: 1, state: .incomplete),
        ])

        // Act

        let actual = summary.memberContributions(members: Self.members)

        // Assert

        let expected: [TodayMemberContribution] = [
            .init(userId: "ownUserId", userName: "自分", completedCount: 0, point: 0),
            .init(userId: "otherUserId", userName: "同居人", completedCount: 0, point: 0),
        ]
        #expect(actual == expected)
    }

    @Test("メンバーに含まれない実行者の家事は集計しない")
    func ignoresItemsExecutedByNonMembers() {
        // Arrange

        let summary = TodayHouseworkSummary.makeForTest(allItems: [
            .makeForTest(id: 1, point: 10, state: .completed, executorId: "leftUserId"),
            .makeForTest(id: 2, point: 20, state: .completed, executorId: "otherUserId"),
        ])

        // Act

        let actual = summary.memberContributions(members: Self.members)

        // Assert

        let expected: [TodayMemberContribution] = [
            .init(userId: "ownUserId", userName: "自分", completedCount: 0, point: 0),
            .init(userId: "otherUserId", userName: "同居人", completedCount: 1, point: 20),
        ]
        #expect(actual == expected)
    }

}
