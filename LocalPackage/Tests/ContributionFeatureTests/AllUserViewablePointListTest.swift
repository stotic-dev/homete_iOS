//
//  AllUserViewablePointListTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import Foundation
import Testing
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct AllUserViewablePointListTest {
    struct MakeCase {
        private let calendar = Calendar.japanese
    }
}

extension AllUserViewablePointListTest.MakeCase {

    @Test("週間データの場合はxAxisDatesが1日刻みで設定される")
    func make_setsXScaleDomainAndXAxisDates_forWeekData() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 21; let april21 = try #require(calendar.date(from: comps))
        comps.day = 22; let april22 = try #require(calendar.date(from: comps))
        comps.day = 23; let april23 = try #require(calendar.date(from: comps))
        comps.day = 24; let april24 = try #require(calendar.date(from: comps))
        comps.day = 25; let april25 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let list = [PointOfWeek(userId: "u1", userName: "u1", total: .init(value: 0), elements: [], startDate: april20)]

        // Act
        let result = AllUserViewablePointList.make(
            list: list,
            displayPeriod: .week,
            dateRange: april20...april26,
            calendar: calendar
        )

        // Assert
        let expected = AllUserViewablePointList(
            list: list.map { $0.generate() },
            displayPeriod: .week,
            xAxisDates: [april20, april21, april22, april23, april24, april25, april26],
            dateRange: april20...april26
        )
        #expect(result == expected)
    }

    @Test("月間データの場合はxAxisDatesが5日刻みで設定される")
    func make_setsXScaleDomainAndXAxisDates_forMonthData() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 1;  let april1  = try #require(calendar.date(from: comps))
        comps.day = 6;  let april6  = try #require(calendar.date(from: comps))
        comps.day = 11; let april11 = try #require(calendar.date(from: comps))
        comps.day = 16; let april16 = try #require(calendar.date(from: comps))
        comps.day = 21; let april21 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        comps.day = 30; let april30 = try #require(calendar.date(from: comps))
        let list = [PointOfMonth(userId: "u1", userName: "u1", total: .init(value: 0), elements: [], startDate: april1)]

        // Act
        let result = AllUserViewablePointList.make(
            list: list,
            displayPeriod: .month,
            dateRange: april1...april30,
            calendar: calendar
        )

        // Assert
        let expected = AllUserViewablePointList(
            list: list.map { $0.generate() },
            displayPeriod: .month,
            xAxisDates: [april1, april6, april11, april16, april21, april26, april30],
            dateRange: april1...april30
        )
        #expect(result == expected)
    }

    @Test("年間データの場合はxAxisDatesが月初日刻みで設定される")
    func make_setsXScaleDomainAndXAxisDates_forYearData() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.day = 1
        let months: [Date] = try (1...12).map { month in
            comps.month = month
            return try #require(calendar.date(from: comps))
        }
        comps.month = 12; comps.day = 31
        let yearEnd = try #require(calendar.date(from: comps))
        let list = [PointOfYear(
            userId: "u1",
            userName: "u1",
            total: .init(value: 0),
            elements: [],
            dateRange: months[0]...yearEnd
        )]

        // Act
        let result = AllUserViewablePointList.make(
            list: list,
            displayPeriod: .year,
            dateRange: months[0]...yearEnd,
            calendar: calendar
        )

        // Assert
        let expected = AllUserViewablePointList(
            list: list.map { $0.generate() },
            displayPeriod: .year,
            xAxisDates: months,
            dateRange: months[0]...yearEnd
        )
        #expect(result == expected)
    }
}
