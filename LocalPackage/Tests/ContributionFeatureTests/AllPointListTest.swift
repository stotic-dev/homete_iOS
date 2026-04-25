//
//  AllPointListTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import Testing
import HometeDomain
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct AllPointListTest {
    struct MakeCase {
        private let calendar = makeTestCalendar()
    }
    struct ViewablePointListCase {
        private let calendar = makeTestCalendar()
    }
}

extension AllPointListTest.MakeCase {

    @Test("完了した家事のみPointOfDayリストに変換される")
    func make_onlyCompletedItemsAreIncluded() {

        // Arrange
        let items: [HouseworkItem] = [
            .makeForTest(id: 1, point: 30, state: .completed),
            .makeForTest(id: 2, point: 50, state: .incomplete),
            .makeForTest(id: 3, point: 20, state: .completed),
        ]

        // Act
        let result = AllPointList.make(by: items, calendar: calendar)

        // Assert
        #expect(result.list.count == 2)
    }

    @Test("完了家事のポイントと日付がPointOfDayに正しく変換される")
    func make_pointAndDateAreMappedCorrectly() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: april10, point: 30, state: .completed)

        // Act
        let result = AllPointList.make(by: [item], calendar: calendar)

        // Assert
        let pointOfDay = try #require(result.list.first)
        #expect(pointOfDay.indexedDay == april10)
        #expect(pointOfDay.point.value == 30)
    }

    @Test("家事が空の場合は空のリストが返る")
    func make_emptyInput_returnsEmptyList() {

        // Arrange
        let items: [HouseworkItem] = []

        // Act
        let result = AllPointList.make(by: items, calendar: calendar)

        // Assert
        #expect(result.list.isEmpty)
    }
}

extension AllPointListTest.ViewablePointListCase {

    @Test("年単位のviewablePointListは指定年の家事のみ集計する")
    func viewablePointList_yearOverload_filtersToTargetYear() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april2026 = try #require(calendar.date(from: comps))
        comps.year = 2025
        let april2025 = try #require(calendar.date(from: comps))

        let items: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: april2026, point: 30, state: .completed),
            .makeForTest(id: 2, indexedDate: april2025, point: 50, state: .completed),
        ]
        let allPointList = AllPointList.make(by: items, calendar: calendar)
        let period2026 = calendar.dateComponents([.year], from: april2026)

        // Act
        let result: PointOfYear = allPointList.viewablePointList(period: period2026, calendar: calendar)

        // Assert
        #expect(result.total.value == 30)
    }

    @Test("月単位のviewablePointListは指定月の家事のみ集計する")
    func viewablePointList_monthOverload_filtersToTargetMonth() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))
        comps.month = 3
        let march10 = try #require(calendar.date(from: comps))

        let items: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: april10, point: 30, state: .completed),
            .makeForTest(id: 2, indexedDate: march10, point: 50, state: .completed),
        ]
        let allPointList = AllPointList.make(by: items, calendar: calendar)
        let aprilPeriod = calendar.dateComponents([.year, .month], from: april10)

        // Act
        let result: PointOfMonth = allPointList.viewablePointList(period: aprilPeriod, calendar: calendar)

        // Assert
        #expect(result.total.value == 30)
    }
}

private func makeTestCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "ja_JP")
    cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return cal
}
