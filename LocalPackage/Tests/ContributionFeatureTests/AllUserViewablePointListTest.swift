// swiftlint:disable file_length
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
    struct CalcCumulativeEntriesCase {
        private let calendar = Calendar.japanese
    }
    struct CumulativeEntriesForDateCase {
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
            dateRange: april20...april26,
            cumulativeEntries: []
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
            dateRange: april1...april30,
            cumulativeEntries: []
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
            dateRange: months[0]...yearEnd,
            cumulativeEntries: []
        )
        #expect(result == expected)
    }
}

extension AllUserViewablePointListTest.CalcCumulativeEntriesCase {

    @Test("単一ユーザーの累計ポイントが日付順に正しく計算される")
    func make_calcsCumulativeEntries_forSingleUser() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 22; let april22 = try #require(calendar.date(from: comps))
        comps.day = 25; let april25 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let list = [
            PointOfWeek.make(
                by: [
                    .init(indexedDay: april20, point: .init(value: 10)),
                    .init(indexedDay: april22, point: .init(value: 30)),
                    .init(indexedDay: april25, point: .init(value: 20))
                ],
                userId: "u1",
                userName: "田中",
                dateRange: april20...april26,
                calendar: calendar
            )
        ]

        // Act
        let result = AllUserViewablePointList.make(
            list: list,
            displayPeriod: .week,
            dateRange: april20...april26,
            calendar: calendar
        )

        // Assert
        let entries = result.cumulativeEntries.sorted { $0.date < $1.date }
        #expect(entries.count == 3)
        #expect(entries[0].date == april20)
        #expect(entries[0].cumulativePoint == 10)
        #expect(entries[1].date == april22)
        #expect(entries[1].cumulativePoint == 40)
        #expect(entries[2].date == april25)
        #expect(entries[2].cumulativePoint == 60)
    }

    @Test("複数ユーザーの場合、ユーザーごとに独立して累計計算される")
    func make_calcsCumulativeEntries_perUserIndependently() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 21; let april21 = try #require(calendar.date(from: comps))
        comps.day = 22; let april22 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let list = [
            PointOfWeek.make(
                by: [
                    .init(indexedDay: april20, point: .init(value: 10)),
                    .init(indexedDay: april22, point: .init(value: 30))
                ],
                userId: "u1",
                userName: "田中",
                dateRange: april20...april26,
                calendar: calendar
            ),
            PointOfWeek.make(
                by: [
                    .init(indexedDay: april21, point: .init(value: 5)),
                    .init(indexedDay: april22, point: .init(value: 15))
                ],
                userId: "u2",
                userName: "佐藤",
                dateRange: april20...april26,
                calendar: calendar
            )
        ]

        // Act
        let result = AllUserViewablePointList.make(
            list: list,
            displayPeriod: .week,
            dateRange: april20...april26,
            calendar: calendar
        )

        // Assert
        let u1 = result.cumulativeEntries.filter { $0.userName == "田中" }.sorted { $0.date < $1.date }
        let u2 = result.cumulativeEntries.filter { $0.userName == "佐藤" }.sorted { $0.date < $1.date }
        #expect(u1.count == 2)
        #expect(u1[0].cumulativePoint == 10)
        #expect(u1[1].cumulativePoint == 40)
        #expect(u2.count == 2)
        #expect(u2[0].cumulativePoint == 5)
        #expect(u2[1].cumulativePoint == 20)
    }

    @Test("ポイントデータがない場合は空配列が返される")
    func make_returnsEmptyCumulativeEntries_whenNoElements() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let list = [PointOfWeek(userId: "u1", userName: "田中", total: .init(value: 0), elements: [], startDate: april20)]

        // Act
        let result = AllUserViewablePointList.make(
            list: list,
            displayPeriod: .week,
            dateRange: april20...april26,
            calendar: calendar
        )

        // Assert
        #expect(result.cumulativeEntries.isEmpty)
    }
}

extension AllUserViewablePointListTest.CumulativeEntriesForDateCase {

    @Test("指定した日付に一致する累計エントリが返される（日粒度）")
    func cumulativeEntriesForDate_returnsMatchingEntries_forDayGranularity() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 22; let april22 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let list = [
            PointOfWeek.make(
                by: [
                    .init(indexedDay: april20, point: .init(value: 10)),
                    .init(indexedDay: april22, point: .init(value: 30))
                ],
                userId: "u1",
                userName: "田中",
                dateRange: april20...april26,
                calendar: calendar
            )
        ]
        let sut = AllUserViewablePointList.make(
            list: list,
            displayPeriod: .week,
            dateRange: april20...april26,
            calendar: calendar
        )

        // Act
        let entries = sut.cumulativeEntries(for: april22, calendar: calendar)

        // Assert
        #expect(entries.count == 1)
        #expect(entries[0].userName == "田中")
        #expect(entries[0].cumulativePoint == 40)
    }

    @Test("データがない日付を指定した場合は空配列が返される")
    func cumulativeEntriesForDate_returnsEmpty_whenNoDataForDate() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 23; let april23 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let list = [
            PointOfWeek.make(
                by: [.init(indexedDay: april20, point: .init(value: 10))],
                userId: "u1",
                userName: "田中",
                dateRange: april20...april26,
                calendar: calendar
            )
        ]
        let sut = AllUserViewablePointList.make(
            list: list,
            displayPeriod: .week,
            dateRange: april20...april26,
            calendar: calendar
        )

        // Act
        let entries = sut.cumulativeEntries(for: april23, calendar: calendar)

        // Assert
        #expect(entries.isEmpty)
    }

    @Test("年間データの場合は月粒度でフィルタリングされる")
    func cumulativeEntriesForDate_filtersWithMonthGranularity_forYearPeriod() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 1; comps.day = 1; let jan1 = try #require(calendar.date(from: comps))
        comps.month = 3; comps.day = 15; let mar15 = try #require(calendar.date(from: comps))
        comps.month = 3; comps.day = 1; let mar1 = try #require(calendar.date(from: comps))
        comps.month = 12; comps.day = 31; let dec31 = try #require(calendar.date(from: comps))
        let list = [
            PointOfYear.make(
                by: [
                    .init(indexedDay: jan1, point: .init(value: 20)),
                    .init(indexedDay: mar15, point: .init(value: 30))
                ],
                userId: "u1",
                userName: "田中",
                dateRange: jan1...dec31,
                calendar: calendar
            )
        ]
        let sut = AllUserViewablePointList.make(
            list: list,
            displayPeriod: .year,
            dateRange: jan1...dec31,
            calendar: calendar
        )

        // Act: 3月1日で検索（mar15 と同月）
        let entries = sut.cumulativeEntries(for: mar1, calendar: calendar)

        // Assert
        #expect(entries.count == 1)
        #expect(entries[0].cumulativePoint == 50)
    }
}
