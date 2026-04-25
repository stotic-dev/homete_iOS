//
//  PointOfMonthTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import Testing
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct PointOfMonthTest {
    struct MakeCase {
        private let calendar = makeTestCalendar()
    }
    struct MakeWithSeparatedCase {
        private let calendar = makeTestCalendar()
    }
}

extension PointOfMonthTest.MakeCase {

    @Test("指定月以外のPointOfDayは除外され、指定月のみ集計される")
    func make_excludesItemsOutsideTargetMonth() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))
        comps.month = 5; comps.day = 10
        let may10 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april10, point: Point(value: 30)),
            PointOfDay(indexedDay: may10, point: Point(value: 50)),
        ]
        let aprilPeriod = calendar.dateComponents([.year, .month], from: april10)

        // Act
        let result = PointOfMonth.make(period: aprilPeriod, by: dayOfPoints, calendar: calendar)

        // Assert
        #expect(result.elements.count == 1)
        #expect(result.total.value == 30)
    }

    @Test("指定月に含まれる全PointOfDayのポイントが合算される")
    func make_totalIsSumOfTargetMonthItemPoints() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))
        comps.day = 20
        let april20 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april10, point: Point(value: 30)),
            PointOfDay(indexedDay: april20, point: Point(value: 50)),
        ]
        let aprilPeriod = calendar.dateComponents([.year, .month], from: april10)

        // Act
        let result = PointOfMonth.make(period: aprilPeriod, by: dayOfPoints, calendar: calendar)

        // Assert
        #expect(result.total.value == 80)
    }
}

extension PointOfMonthTest.MakeWithSeparatedCase {

    @Test("同じ月のPointOfDayが1つのPointOfMonthにまとめられる")
    func makeWithSeparated_sameMonthItemsAreGroupedTogether() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))
        comps.day = 20
        let april20 = try #require(calendar.date(from: comps))
        comps.month = 5; comps.day = 10
        let may10 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april10, point: Point(value: 30)),
            PointOfDay(indexedDay: april20, point: Point(value: 50)),
            PointOfDay(indexedDay: may10, point: Point(value: 20)),
        ]

        // Act
        let result = PointOfMonth.makeWithSeparated(by: dayOfPoints, calendar: calendar)

        // Assert
        #expect(result.count == 2)
    }

    @Test("各月のポイントの合計が正しく計算される")
    func makeWithSeparated_totalPerMonthIsCorrect() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))
        comps.day = 20
        let april20 = try #require(calendar.date(from: comps))
        comps.month = 5; comps.day = 10
        let may10 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april10, point: Point(value: 30)),
            PointOfDay(indexedDay: april20, point: Point(value: 50)),
            PointOfDay(indexedDay: may10, point: Point(value: 20)),
        ]

        // Act
        let result = PointOfMonth.makeWithSeparated(by: dayOfPoints, calendar: calendar)

        // Assert
        let aprilMonth = try #require(result.first)
        let mayMonth = try #require(result.last)
        #expect(aprilMonth.total.value == 80)
        #expect(mayMonth.total.value == 20)
    }
}

private func makeTestCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "ja_JP")
    cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return cal
}
