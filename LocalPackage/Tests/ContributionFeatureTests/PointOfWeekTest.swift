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
        private let calendar = Calendar.japanese
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
            PointOfDay(indexedDay: april27, point: Point(value: 20))
        ]
        let weekPeriod = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: april20)

        // Act
        let result = PointOfWeek.make(period: weekPeriod, by: dayOfPoints, calendar: calendar)

        // Assert
        let expected = PointOfWeek(
            displayPeriod: .init(type: .week, components: weekPeriod),
            total: .init(value: 80),
            elements: [
                PointOfDay(indexedDay: april20, point: Point(value: 30)),
                PointOfDay(indexedDay: april21, point: Point(value: 50))
            ]
        )
        #expect(result == expected)
    }
}
