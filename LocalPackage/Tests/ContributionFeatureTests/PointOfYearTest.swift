//
//  PointOfYearTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import Testing
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct PointOfYearTest {
    struct MakeCase {
        private let calendar = Calendar.japanese
    }
}

extension PointOfYearTest.MakeCase {

    @Test("指定年以外のPointOfDayは除外される")
    func make_excludesItemsOutsideTargetYear() throws {

        // Arrange
        let yearDates2026: [Date] = (1...12).map { month in
            Date.previewDate(year: 2026, month: month, day: 1)
        }
        let april2026 = Date.previewDate(year: 2026, month: 4, day: 10)
        let april2025 = Date.previewDate(year: 2025, month: 4, day: 10)

        let dayOfPoints: [Date: PointOfDay] = [
            april2026: PointOfDay(indexedDay: april2026, point: Point(value: 30)),
            april2025: PointOfDay(indexedDay: april2025, point: Point(value: 50))
        ]

        // Act
        let result = PointOfYear.make(
            by: dayOfPoints,
            userId: "testUser",
            userName: "テストユーザー",
            dates: yearDates2026,
            calendar: calendar
        )

        // Assert
        #expect(result.total.value == 30)
    }

    @Test("指定年の家事が月ごとにグループ化される")
    func make_elementsAreGroupedByMonth() throws {

        // Arrange
        let yearDates2026: [Date] = (1...12).map { month in
            Date.previewDate(year: 2026, month: month, day: 1)
        }
        let april2026 = Date.previewDate(year: 2026, month: 4, day: 10)
        let may2026 = Date.previewDate(year: 2026, month: 5, day: 10)

        let dayOfPoints: [Date: PointOfDay] = [
            april2026: PointOfDay(indexedDay: april2026, point: Point(value: 30)),
            may2026: PointOfDay(indexedDay: may2026, point: Point(value: 50))
        ]

        // Act
        let result = PointOfYear.make(
            by: dayOfPoints,
            userId: "testUser",
            userName: "テストユーザー",
            dates: yearDates2026,
            calendar: calendar
        )

        // Assert: 全12ヶ月分のelementsが返る（データなしの月も補完される）
        #expect(result.elements.count == yearDates2026.count)
        #expect(result.elements.contains { $0.total.value == 30 })
        #expect(result.elements.contains { $0.total.value == 50 })
    }

    @Test("指定年に含まれる全月のポイントが合算される")
    func make_totalIsSumOfAllTargetYearItemPoints() throws {

        // Arrange
        let yearDates2026: [Date] = (1...12).map { month in
            Date.previewDate(year: 2026, month: month, day: 1)
        }
        let april2026 = Date.previewDate(year: 2026, month: 4, day: 10)
        let may2026 = Date.previewDate(year: 2026, month: 5, day: 10)

        let dayOfPoints: [Date: PointOfDay] = [
            april2026: PointOfDay(indexedDay: april2026, point: Point(value: 30)),
            may2026: PointOfDay(indexedDay: may2026, point: Point(value: 50))
        ]

        // Act
        let result = PointOfYear.make(
            by: dayOfPoints,
            userId: "testUser",
            userName: "テストユーザー",
            dates: yearDates2026,
            calendar: calendar
        )

        // Assert
        #expect(result.total.value == 80)
    }
}
