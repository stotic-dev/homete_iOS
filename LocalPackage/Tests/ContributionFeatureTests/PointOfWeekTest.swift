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
        // 2026-04-20(月)〜2026-04-26(日) の週、2026-04-27(月) は翌週
        let weekDates: [Date] = (20...26).map { day in
            Date.previewDate(year: 2026, month: 4, day: day)
        }
        let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
        let april21 = Date.previewDate(year: 2026, month: 4, day: 21)
        let april27 = Date.previewDate(year: 2026, month: 4, day: 27)

        let dayOfPoints = [
            PointOfDay(indexedDay: april20, point: Point(value: 30)),
            PointOfDay(indexedDay: april21, point: Point(value: 50)),
            PointOfDay(indexedDay: april27, point: Point(value: 20))
        ]

        // Act
        let result = PointOfWeek.make(
            by: dayOfPoints,
            userId: "testUser",
            userName: "テストユーザー",
            dates: weekDates,
            calendar: calendar
        )

        // Assert: 指定週外の april27 は除外され、データなしの日は0で補完される
        #expect(result.total.value == 80)
        #expect(result.elements.count == weekDates.count)
        #expect(result.startDate == april20)
        #expect(result.elements.contains { $0.indexedDay == april20 && $0.point.value == 30 })
        #expect(result.elements.contains { $0.indexedDay == april21 && $0.point.value == 50 })
        for missingDay in [22, 23, 24, 25, 26] {
            let date = Date.previewDate(year: 2026, month: 4, day: missingDay)
            #expect(result.elements.contains { $0.indexedDay == date && $0.point.value == 0 })
        }
    }
}
