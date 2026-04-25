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
        private let calendar = makeTestCalendar()
    }
}

extension PointOfYearTest.MakeCase {

    @Test("指定年以外のPointOfDayは除外される")
    func make_excludesItemsOutsideTargetYear() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april2026 = try #require(calendar.date(from: comps))
        comps.year = 2025
        let april2025 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april2026, point: Point(value: 30)),
            PointOfDay(indexedDay: april2025, point: Point(value: 50)),
        ]
        let period2026 = calendar.dateComponents([.year], from: april2026)

        // Act
        let result = PointOfYear.make(period: period2026, by: dayOfPoints, calendar: calendar)

        // Assert
        #expect(result.total.value == 30)
    }

    @Test("指定年の家事が月ごとにグループ化される")
    func make_elementsAreGroupedByMonth() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april2026 = try #require(calendar.date(from: comps))
        comps.month = 5
        let may2026 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april2026, point: Point(value: 30)),
            PointOfDay(indexedDay: may2026, point: Point(value: 50)),
        ]
        let period2026 = calendar.dateComponents([.year], from: april2026)

        // Act
        let result = PointOfYear.make(period: period2026, by: dayOfPoints, calendar: calendar)

        // Assert
        #expect(result.elements.count == 2)
    }

    @Test("指定年に含まれる全月のポイントが合算される")
    func make_totalIsSumOfAllTargetYearItemPoints() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april2026 = try #require(calendar.date(from: comps))
        comps.month = 5
        let may2026 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april2026, point: Point(value: 30)),
            PointOfDay(indexedDay: may2026, point: Point(value: 50)),
        ]
        let period2026 = calendar.dateComponents([.year], from: april2026)

        // Act
        let result = PointOfYear.make(period: period2026, by: dayOfPoints, calendar: calendar)

        // Assert
        #expect(result.total.value == 80)
    }
}

private func makeTestCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "ja_JP")
    cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return cal
}
