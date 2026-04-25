//
//  PointOfWeekTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import Testing
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct PointOfWeekTest {
    struct MakeCase {
        private let calendar = makeTestCalendar()
    }
    struct MakeWithSeparatedCase {
        private let calendar = makeTestCalendar()
    }
}

extension PointOfWeekTest.MakeCase {

    @Test("指定週以外のPointOfDayは除外され、指定週のポイントが合算される")
    func make_onlyTargetWeekItemsAreIncludedAndSummed() throws {

        // Arrange
        // 2026-04-20(月), 2026-04-21(火) は同じ週、2026-04-27(月) は翌週
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 20
        let april20 = try #require(calendar.date(from: comps))
        comps.day = 21
        let april21 = try #require(calendar.date(from: comps))
        comps.day = 27
        let april27 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april20, point: Point(value: 30)),
            PointOfDay(indexedDay: april21, point: Point(value: 50)),
            PointOfDay(indexedDay: april27, point: Point(value: 20)),
        ]
        let weekPeriod = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: april20)

        // Act
        let result = PointOfWeek.make(period: weekPeriod, by: dayOfPoints, calendar: calendar)

        // Assert
        #expect(result.elements.count == 2)
        #expect(result.total.value == 80)
    }
}

extension PointOfWeekTest.MakeWithSeparatedCase {

    @Test("同じ週のPointOfDayが1つのPointOfWeekにまとめられる")
    func makeWithSeparated_sameWeekItemsAreGroupedTogether() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 20
        let april20 = try #require(calendar.date(from: comps))
        comps.day = 21
        let april21 = try #require(calendar.date(from: comps))
        comps.day = 27
        let april27 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april20, point: Point(value: 30)),
            PointOfDay(indexedDay: april21, point: Point(value: 50)),
            PointOfDay(indexedDay: april27, point: Point(value: 20)),
        ]

        // Act
        let result = PointOfWeek.makeWithSeparated(by: dayOfPoints, calendar: calendar)

        // Assert
        #expect(result.count == 2)
    }

    @Test("各週のポイントの合計が正しく計算される")
    func makeWithSeparated_totalPerWeekIsCorrect() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 20
        let april20 = try #require(calendar.date(from: comps))
        comps.day = 21
        let april21 = try #require(calendar.date(from: comps))
        comps.day = 27
        let april27 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april20, point: Point(value: 30)),
            PointOfDay(indexedDay: april21, point: Point(value: 50)),
            PointOfDay(indexedDay: april27, point: Point(value: 20)),
        ]

        // Act
        let result = PointOfWeek.makeWithSeparated(by: dayOfPoints, calendar: calendar)

        // Assert
        let firstWeek = try #require(result.first)
        let secondWeek = try #require(result.last)
        #expect(firstWeek.total.value == 80)
        #expect(secondWeek.total.value == 20)
    }
}

private func makeTestCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "ja_JP")
    cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return cal
}
