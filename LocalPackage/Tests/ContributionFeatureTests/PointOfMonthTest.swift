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
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 1
        let aprilStart = try #require(calendar.date(from: comps))
        comps.day = 10
        let april10 = try #require(calendar.date(from: comps))
        comps.day = 20
        let april20 = try #require(calendar.date(from: comps))
        comps.day = 30
        let aprilEnd = try #require(calendar.date(from: comps))
        comps.month = 5; comps.day = 10
        let may10 = try #require(calendar.date(from: comps))

        let dayOfPoints = [
            PointOfDay(indexedDay: april10, point: Point(value: 30)),
            PointOfDay(indexedDay: april20, point: Point(value: 50)),
            PointOfDay(indexedDay: may10, point: Point(value: 50))
        ]
        let aprilRange = aprilStart...aprilEnd

        // Act
        let result = PointOfMonth.make(
            by: dayOfPoints,
            userId: "testUser",
            userName: "テストユーザー",
            dateRange: aprilRange,
            calendar: calendar
        )

        // Assert
        let expected = PointOfMonth(
            userId: "testUser",
            userName: "テストユーザー",
            total: .init(value: 80),
            elements: [
                PointOfDay(indexedDay: april10, point: Point(value: 30)),
                PointOfDay(indexedDay: april20, point: Point(value: 50))
            ],
            startDate: aprilStart
        )
        #expect(result == expected)
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
            PointOfDay(indexedDay: may10, point: Point(value: 20))
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
