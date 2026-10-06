//
//  EncouragementContextTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct EncouragementContextTest {

    private let calendar = Calendar.japanese
    private let now = Date.previewDate(year: 2026, month: 10, day: 6, hour: 20)
    private let members = CohabitantMemberList(
        value: [
            .init(id: "own", userName: "たろう"),
            .init(id: "partner", userName: "はなこ"),
        ],
        ownId: "own"
    )

    @Test("家事がなければ、実績はすべて0になる")
    func make_noItems_returnsEmptyActivity() {
        // Act
        let actual = EncouragementContext.make(
            allItems: [],
            members: members,
            todayTotalCount: 0,
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = EncouragementContext(
            own: .init(
                todayCompletedTitles: [],
                todayCompletedCount: 0,
                todayEffortfulCount: 0,
                weeklyCompletedCount: 0,
                streakDays: 0
            ),
            today: .init(totalCount: 0, completedCount: 0),
            monthlyMembers: [
                .init(userName: "たろう", isOwn: true, completedCount: 0, point: 0, frequentTitles: []),
                .init(userName: "はなこ", isOwn: false, completedCount: 0, point: 0, frequentTitles: []),
            ]
        )
        #expect(actual == expected)
    }

    @Test("今日の自分の実績は、完了した順のタイトル・件数・頑張り度を集計し、未完了と他人の家事は数えない")
    func make_todayItems_returnsOwnTodayActivity() {
        // Arrange
        let today = Date.previewDate(year: 2026, month: 10, day: 6)
        let items: [HouseworkItem] = [
            .makeForTest(
                id: 1,
                indexedDate: today,
                title: "洗濯",
                state: .completed,
                executorId: "own",
                effort: .hard,
                executedAt: .previewDate(year: 2026, month: 10, day: 6, hour: 12)
            ),
            .makeForTest(
                id: 2,
                indexedDate: today,
                title: "洗い物",
                state: .completed,
                executorId: "own",
                executedAt: .previewDate(year: 2026, month: 10, day: 6, hour: 8)
            ),
            .makeForTest(id: 3, indexedDate: today, title: "掃除", state: .incomplete),
            .makeForTest(id: 4, indexedDate: today, title: "料理", state: .completed, executorId: "partner"),
        ]

        // Act
        let actual = EncouragementContext.make(
            allItems: items,
            members: members,
            todayTotalCount: 4,
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = EncouragementContext.OwnActivity(
            todayCompletedTitles: ["洗い物", "洗濯"],
            todayCompletedCount: 2,
            todayEffortfulCount: 1,
            weeklyCompletedCount: 2,
            streakDays: 1
        )
        #expect(actual.own == expected)
    }

    @Test("今日の進み具合は、世帯全体で今日完了した件数と、渡された今日の件数を持つ")
    func make_todayItems_returnsTodayProgress() {
        // Arrange
        let today = Date.previewDate(year: 2026, month: 10, day: 6)
        let items: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: today, state: .completed, executorId: "own"),
            .makeForTest(id: 2, indexedDate: today, state: .completed, executorId: "partner"),
            .makeForTest(id: 3, indexedDate: today, state: .incomplete),
            .makeForTest(
                id: 4,
                indexedDate: .previewDate(year: 2026, month: 10, day: 5),
                state: .completed,
                executorId: "own"
            ),
        ]

        // Act
        let actual = EncouragementContext.make(
            allItems: items,
            members: members,
            todayTotalCount: 5,
            now: now,
            calendar: calendar
        )

        // Assert
        #expect(actual.today == .init(totalCount: 5, completedCount: 2))
    }

    @Test("直近7日の件数は今日を含む7日間を数え、連続日数は今日から途切れるまでを数える")
    func make_pastItems_returnsWeeklyCountAndStreak() {
        // Arrange
        // 9/29は直近7日（9/30〜10/6）の外
        let items: [HouseworkItem] = [6, 5, 4, 2, 1, 29].enumerated().map { index, day in
            let month = day == 29 ? 9 : 10
            return .makeForTest(
                id: index,
                indexedDate: .previewDate(year: 2026, month: month, day: day),
                state: .completed,
                executorId: "own"
            )
        }

        // Act
        let actual = EncouragementContext.make(
            allItems: items,
            members: members,
            todayTotalCount: 1,
            now: now,
            calendar: calendar
        )

        // Assert
        let expected = EncouragementContext.OwnActivity(
            todayCompletedTitles: ["title"],
            todayCompletedCount: 1,
            todayEffortfulCount: 0,
            weeklyCompletedCount: 5,
            streakDays: 3
        )
        #expect(actual.own == expected)
    }

    @Test("今月のメンバー別の貢献度は、担当者ごとの件数・ポイント・よくした家事を集計し、先月の家事は数えない")
    func make_monthItems_returnsMonthlyMembers() {
        // Arrange
        let items: [HouseworkItem] = [
            .makeForTest(
                id: 1,
                indexedDate: .previewDate(year: 2026, month: 10, day: 1),
                title: "洗濯",
                state: .completed,
                executors: [
                    .init(userId: "own", percentage: 50, point: 10),
                    .init(userId: "partner", percentage: 50, point: 10),
                ]
            ),
            .makeForTest(
                id: 2,
                indexedDate: .previewDate(year: 2026, month: 10, day: 2),
                title: "洗濯",
                point: 20,
                state: .completed,
                executorId: "own"
            ),
            .makeForTest(
                id: 3,
                indexedDate: .previewDate(year: 2026, month: 10, day: 3),
                title: "掃除",
                point: 30,
                state: .completed,
                executorId: "own"
            ),
            .makeForTest(
                id: 4,
                indexedDate: .previewDate(year: 2026, month: 9, day: 30),
                title: "料理",
                point: 50,
                state: .completed,
                executorId: "partner"
            ),
        ]

        // Act
        let actual = EncouragementContext.make(
            allItems: items,
            members: members,
            todayTotalCount: 0,
            now: now,
            calendar: calendar
        )

        // Assert
        let expected: [EncouragementContext.MonthlyMemberContribution] = [
            .init(userName: "たろう", isOwn: true, completedCount: 3, point: 60, frequentTitles: ["洗濯", "掃除"]),
            .init(userName: "はなこ", isOwn: false, completedCount: 1, point: 10, frequentTitles: ["洗濯"]),
        ]
        #expect(actual.monthlyMembers == expected)
    }

}
