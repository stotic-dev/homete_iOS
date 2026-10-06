//
//  EncouragementMilestoneTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct EncouragementMilestoneTest {

    @Test(
        "自分の今日の件数と、今日の家事が全部終わったかで節目を決める",
        arguments: [
            (ownCount: 0, total: 3, completed: 3, expected: EncouragementMilestone.noActivity),
            (ownCount: 1, total: 3, completed: 2, expected: .inProgress),
            (ownCount: 1, total: 3, completed: 3, expected: .allCompleted),
            (ownCount: 1, total: 0, completed: 1, expected: .inProgress),
        ]
    )
    func init_context_returnsMilestone(
        ownCount: Int,
        total: Int,
        completed: Int,
        expected: EncouragementMilestone
    ) {
        // Arrange
        let context = EncouragementContext(
            own: .init(
                todayCompletedTitles: [],
                todayCompletedCount: ownCount,
                todayEffortfulCount: 0,
                weeklyCompletedCount: 0,
                streakDays: 0
            ),
            today: .init(totalCount: total, completedCount: completed),
            monthlyMembers: []
        )

        // Act
        let actual = EncouragementMilestone(context: context)

        // Assert
        #expect(actual == expected)
    }

}
