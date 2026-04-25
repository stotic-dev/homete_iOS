//
//  HouseworkIndexedDate.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import Foundation
import Testing
@testable import HometeDomain

enum HouseworkIndexedDateTest {

    struct InitCase {}
    struct CalcTargetPeriodCase {}
}

// MARK: - CalcTargetPeriodCase

extension HouseworkIndexedDateTest.CalcTargetPeriodCase {

    @Test("指定の日付から指定の期間の日付情報を返す")
    func calcTargetPeriod() {

        // Arrange
        let calendar = Calendar.japanese

        // Act
        let result = HouseworkIndexedDate.calcTargetPeriod(
            anchorDate: .previewDate(year: 2026, month: 2, day: 1),
            offsetDays: 2,
            calendar: calendar
        )

        // Assert
        let expected: [Date] = [
            .previewDate(year: 2026, month: 1, day: 30),
            .previewDate(year: 2026, month: 1, day: 31),
            .previewDate(year: 2026, month: 2, day: 1),
            .previewDate(year: 2026, month: 2, day: 2),
            .previewDate(year: 2026, month: 2, day: 3),
        ]
        #expect(result == expected)
    }

    @Test("指定の期間が0以下の場合、基準日付のみ返す")
    func calcTargetPeriod_zero_offset() {

        // Arrange
        let calendar = Calendar.japanese

        // Act
        let result = HouseworkIndexedDate.calcTargetPeriod(
            anchorDate: .previewDate(year: 2026, month: 1, day: 15),
            offsetDays: 0,
            calendar: calendar
        )

        // Assert
        let expected = [Date.previewDate(year: 2026, month: 1, day: 15)]
        #expect(result == expected)
    }
}
