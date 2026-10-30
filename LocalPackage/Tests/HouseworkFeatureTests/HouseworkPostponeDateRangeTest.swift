//
//  HouseworkPostponeDateRangeTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

enum HouseworkPostponeDateRangeTest {

    struct InitCase {}
    struct CanPostponeCase {}

    /// 今日（2026/1/10 21時）
    static let now = Date.previewDate(year: 2026, month: 1, day: 10, hour: 21)
    /// 今日から7日後まで
    static let selectableRange = Date.previewDate(year: 2026, month: 1, day: 10)
        ... Date.previewDate(year: 2026, month: 1, day: 17)

}

// MARK: - 範囲と最初に選んでおく日

extension HouseworkPostponeDateRangeTest.InitCase {

    @Test("今日の家事は、今日から7日後までを選べて、明日を選んでおく")
    func init_todayItem_selectsTomorrow() {
        // Arrange
        let expected = HouseworkPostponeDateRange(
            selectableRange: HouseworkPostponeDateRangeTest.selectableRange,
            initialDate: .previewDate(year: 2026, month: 1, day: 11),
            currentDate: .previewDate(year: 2026, month: 1, day: 10)
        )

        // Act
        let actual = HouseworkPostponeDateRange(
            itemDate: .previewDate(year: 2026, month: 1, day: 10),
            now: HouseworkPostponeDateRangeTest.now,
            calendar: .japanese
        )

        // Assert
        #expect(actual == expected)
    }

    @Test("過去の家事は、過去へはまわせないので今日を選んでおく")
    func init_pastItem_selectsToday() {
        // Arrange
        let expected = HouseworkPostponeDateRange(
            selectableRange: HouseworkPostponeDateRangeTest.selectableRange,
            initialDate: .previewDate(year: 2026, month: 1, day: 10),
            currentDate: .previewDate(year: 2026, month: 1, day: 5)
        )

        // Act
        let actual = HouseworkPostponeDateRange(
            itemDate: .previewDate(year: 2026, month: 1, day: 5),
            now: HouseworkPostponeDateRangeTest.now,
            calendar: .japanese
        )

        // Assert
        #expect(actual == expected)
    }

    @Test("選べる最も先の日の家事は、翌日が範囲を超えるので、範囲の最後の日を選んでおく")
    func init_lastSelectableDayItem_selectsUpperBound() {
        // Arrange
        let expected = HouseworkPostponeDateRange(
            selectableRange: HouseworkPostponeDateRangeTest.selectableRange,
            initialDate: .previewDate(year: 2026, month: 1, day: 17),
            currentDate: .previewDate(year: 2026, month: 1, day: 17)
        )

        // Act
        let actual = HouseworkPostponeDateRange(
            itemDate: .previewDate(year: 2026, month: 1, day: 17),
            now: HouseworkPostponeDateRangeTest.now,
            calendar: .japanese
        )

        // Assert
        #expect(actual == expected)
    }

}

// MARK: - まわせる日か

extension HouseworkPostponeDateRangeTest.CanPostponeCase {

    @Test(
        "範囲内で、家事の今の日付と違う日だけにまわせる",
        arguments: [
            (Date.previewDate(year: 2026, month: 1, day: 11, hour: 15), true),
            (.previewDate(year: 2026, month: 1, day: 17), true),
            (.previewDate(year: 2026, month: 1, day: 10, hour: 8), false),
            (.previewDate(year: 2026, month: 1, day: 9), false),
            (.previewDate(year: 2026, month: 1, day: 18), false),
        ]
    )
    func canPostpone(date: Date, expected: Bool) {
        // Arrange
        let range = HouseworkPostponeDateRange(
            itemDate: .previewDate(year: 2026, month: 1, day: 10),
            now: HouseworkPostponeDateRangeTest.now,
            calendar: .japanese
        )

        // Act
        let actual = range.canPostpone(to: date, calendar: .japanese)

        // Assert
        #expect(actual == expected)
    }

}
