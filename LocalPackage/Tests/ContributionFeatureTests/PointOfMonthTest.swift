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
        private let calendar = Calendar.japanese
    }
    struct MakeWithSeparatedCase {
        private let calendar = Calendar.japanese
    }
}

extension PointOfMonthTest.MakeCase {

    @Test("指定月以外のPointOfDayは除外され、指定月のみ集計される")
    func make_excludesItemsOutsideTargetMonth() throws {

        // Arrange
        let aprilDates: [Date] = (1...30).map { day in
            Date.previewDate(year: 2026, month: 4, day: day)
        }
        let aprilStart = Date.previewDate(year: 2026, month: 4, day: 1)
        let april10 = Date.previewDate(year: 2026, month: 4, day: 10)
        let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
        let may10 = Date.previewDate(year: 2026, month: 5, day: 10)

        let dayOfPoints: [Date: PointOfDay] = [
            april10: PointOfDay(indexedDay: april10, point: Point(value: 30)),
            april20: PointOfDay(indexedDay: april20, point: Point(value: 50)),
            may10: PointOfDay(indexedDay: may10, point: Point(value: 50))
        ]

        // Act
        let result = PointOfMonth.make(
            by: dayOfPoints,
            userId: "testUser",
            userName: "テストユーザー",
            dates: aprilDates,
            calendar: calendar
        )

        // Assert: may10 は除外され、データなしの日は0で補完される
        #expect(result.total.value == 80)
        #expect(result.elements.count == aprilDates.count)
        #expect(result.startDate == aprilStart)
        #expect(result.elements.contains { $0.indexedDay == april10 && $0.point.value == 30 })
        #expect(result.elements.contains { $0.indexedDay == april20 && $0.point.value == 50 })
        #expect(!result.elements.contains { $0.indexedDay == may10 })
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

        let dayOfPoints: [Date: PointOfDay] = [
            april10: PointOfDay(indexedDay: april10, point: Point(value: 30)),
            april20: PointOfDay(indexedDay: april20, point: Point(value: 50)),
            may10: PointOfDay(indexedDay: may10, point: Point(value: 20))
        ]

        // Act
        let result = PointOfMonth.makeWithSeparated(
            by: dayOfPoints,
            userId: "testUser",
            userName: "テストユーザー",
            calendar: calendar
        )

        // Assert
        let aprilStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let mayStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)))
        let expected: [PointOfMonth] = [
            .init(
                userId: "testUser",
                userName: "テストユーザー",
                total: .init(value: 80),
                totalAchievementCount: 2,
                elements: [
                    PointOfDay(indexedDay: april10, point: Point(value: 30)),
                    PointOfDay(indexedDay: april20, point: Point(value: 50))
                ],
                startDate: aprilStart
            ),
            .init(
                userId: "testUser",
                userName: "テストユーザー",
                total: .init(value: 20),
                totalAchievementCount: 1,
                elements: [
                    PointOfDay(indexedDay: may10, point: Point(value: 20))
                ],
                startDate: mayStart
            )
        ]
        #expect(result.count == expected.count)
        for item in result {
            #expect(expected.contains { $0.elements == item.elements && $0.total == item.total })
        }
    }
}
