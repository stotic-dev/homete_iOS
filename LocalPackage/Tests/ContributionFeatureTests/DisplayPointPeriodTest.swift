//
//  DisplayPointPeriodTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import Foundation
import Testing
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct DisplayPointPeriodTest {
    struct CalcDateRangeCase {
        private let calendar = Calendar.japanese
    }
    struct ShiftPeriodCase {
        private let calendar = Calendar.japanese
    }
}

extension DisplayPointPeriodTest.CalcDateRangeCase {

    @Test("週モードのとき直近7日間のdateRangeが返る")
    func calcDateRange_week_returnsLastSevenDays() throws {

        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 4, day: 26)
        let period = DisplayPointPeriod(type: .week, anchor: anchor)

        // Act
        let result = try #require(period.calcDateRange(calendar: calendar))

        // Assert
        let expectedStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let expectedEnd   = Date.previewDate(year: 2026, month: 4, day: 26)
        #expect(result == expectedStart...expectedEnd)
    }

    @Test("月モードのとき直近1ヶ月間のdateRangeが返る")
    func calcDateRange_month_returnsLastOneMonth() throws {

        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 4, day: 30)
        let period = DisplayPointPeriod(type: .month, anchor: anchor)

        // Act
        let result = try #require(period.calcDateRange(calendar: calendar))

        // Assert
        let expectedStart = Date.previewDate(year: 2026, month: 3, day: 31)
        let expectedEnd = Date.previewDate(year: 2026, month: 4, day: 30)
        #expect(result == expectedStart...expectedEnd)
    }

    @Test("年モードのとき直近1年間のdateRangeが返る")
    func calcDateRange_year_returnsLastOneYear() throws {

        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 12, day: 31)
        let period = DisplayPointPeriod(type: .year, anchor: anchor)

        // Act
        let result = try #require(period.calcDateRange(calendar: calendar))

        // Assert
        let expectedStart = Date.previewDate(year: 2026, month: 1, day: 1)
        let expectedEnd = Date.previewDate(year: 2026, month: 12, day: 31)
        #expect(result == expectedStart...expectedEnd)
    }
}

extension DisplayPointPeriodTest.ShiftPeriodCase {

    @Test("週モードで+1したとき1週間後がanchorになる")
    func shiftPeriod_week_forwardByOne_movesAnchorOneWeekLater() {

        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 4, day: 20)
        let period = DisplayPointPeriod(type: .week, anchor: anchor)

        // Act
        let result = period.shiftPeriod(by: 1, calendar: calendar)

        // Assert
        let expectedAnchor = Date.previewDate(year: 2026, month: 4, day: 27)
        #expect(result == DisplayPointPeriod(type: .week, anchor: expectedAnchor))
    }

    @Test("月モードで-1したとき1ヶ月前がanchorになる")
    func shiftPeriod_month_backByOne_movesAnchorOneMonthEarlier() {

        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 4, day: 30)
        let period = DisplayPointPeriod(type: .month, anchor: anchor)

        // Act
        let result = period.shiftPeriod(by: -1, calendar: calendar)

        // Assert
        let expectedAnchor = Date.previewDate(year: 2026, month: 3, day: 30)
        #expect(result == DisplayPointPeriod(type: .month, anchor: expectedAnchor))
    }

    @Test("年モードで+1したとき1年後がanchorになる")
    func shiftPeriod_year_forwardByOne_movesAnchorOneYearLater() {

        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 12, day: 31)
        let period = DisplayPointPeriod(type: .year, anchor: anchor)

        // Act
        let result = period.shiftPeriod(by: 1, calendar: calendar)

        // Assert
        let expectedAnchor = Date.previewDate(year: 2027, month: 12, day: 31)
        #expect(result == DisplayPointPeriod(type: .year, anchor: expectedAnchor))
    }
}
