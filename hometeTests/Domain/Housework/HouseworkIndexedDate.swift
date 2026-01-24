//
//  HouseworkIndexedDate.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import Foundation
import Testing
@testable import homete

enum HouseworkIndexedDateTest {

    struct InitCase {}
    struct CalcTargetPeriodCase {}
}

// MARK: - InitCase

extension HouseworkIndexedDateTest.InitCase {

    @Test(arguments: [
        Date.distantPast,
        .init(timeIntervalSince1970: .zero),
        .dateComponents(year: 2025, month: 1, day: 1),
        .distantFuture
    ])
    func init_parse_date(inputDate: Date) async throws {
        let indexedDate = HouseworkIndexedDate(inputDate, calendar: .japanese)
        
        let expected = inputDate.formatted(
            Date.FormatStyle(date: .numeric, time: .omitted)
                .year(.extended(minimumLength: 4))
                .month(.twoDigits)
                .day(.twoDigits)
                .locale(.jp)
        )
        #expect(indexedDate.value == expected)
    }
}

// MARK: - CalcTargetPeriodCase

extension HouseworkIndexedDateTest.CalcTargetPeriodCase {

    @Test("指定の日付から指定の期間の日付情報を返す")
    func calcTargetPeriod() {

        // Arrange
        let calendar = Calendar.japanese

        // Act
        let result = HouseworkIndexedDate.calcTargetPeriod(
            anchorDate: .dateComponents(year: 2026, month: 2, day: 1),
            offsetDays: 2,
            calendar: calendar
        )

        // Assert
        let expected = [
            ["value": "2026/01/30"],
            ["value": "2026/01/31"],
            ["value": "2026/02/01"],
            ["value": "2026/02/02"],
            ["value": "2026/02/03"]
        ]
        #expect(result == expected)
    }
    
    @Test("指定の期間が0以下の場合、基準日付のみ返す")
    func calcTargetPeriod_zero_offset() {

        // Arrange
        let calendar = Calendar.japanese

        // Act
        let result = HouseworkIndexedDate.calcTargetPeriod(
            anchorDate: .dateComponents(year: 2026, month: 1, day: 15),
            offsetDays: 0,
            calendar: calendar
        )

        // Assert
        let expected = [["value": "2026/01/15"]]
        #expect(result == expected)
    }
}
