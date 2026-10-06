//
//  EncouragementFixedCommentTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct EncouragementFixedCommentTest {

    private let calendar = Calendar.japanese

    @Test("同じ日なら、時刻が違っても同じ文言を返す")
    func make_sameDay_returnsSameComment() {
        // Arrange
        let morning = EncouragementFixedComment.make(
            milestone: .inProgress,
            now: .previewDate(year: 2026, month: 10, day: 6, hour: 7),
            calendar: calendar
        )

        // Act
        let night = EncouragementFixedComment.make(
            milestone: .inProgress,
            now: .previewDate(year: 2026, month: 10, day: 6, hour: 23),
            calendar: calendar
        )

        // Assert
        #expect(night == morning)
    }

    @Test(
        "前日と同じ文言が続かない",
        arguments: [EncouragementMilestone.noActivity, .inProgress, .allCompleted]
    )
    func make_nextDay_returnsDifferentText(milestone: EncouragementMilestone) {
        // Arrange
        let today = EncouragementFixedComment.make(
            milestone: milestone,
            now: .previewDate(year: 2026, month: 10, day: 6),
            calendar: calendar
        )

        // Act
        let tomorrow = EncouragementFixedComment.make(
            milestone: milestone,
            now: .previewDate(year: 2026, month: 10, day: 7),
            calendar: calendar
        )

        // Assert
        #expect(tomorrow.text != today.text)
    }

    @Test(
        "実績がない日は中立のコメント、それ以外はねぎらいのコメントとして返す",
        arguments: [
            (milestone: EncouragementMilestone.noActivity, expected: EncouragementComment.Kind.neutral),
            (milestone: .inProgress, expected: .selfPraise),
            (milestone: .allCompleted, expected: .selfPraise),
        ]
    )
    func make_milestone_returnsKind(milestone: EncouragementMilestone, expected: EncouragementComment.Kind) {
        // Act
        let actual = EncouragementFixedComment.make(
            milestone: milestone,
            now: .previewDate(year: 2026, month: 10, day: 6),
            calendar: calendar
        )

        // Assert
        #expect(actual.kind == expected)
    }

}
