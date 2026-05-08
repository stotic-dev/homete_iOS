//
//  AllUserCumulativeDataTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/07.
//

import Foundation
import Testing
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct AllUserCumulativeDataTest {
    struct MakeCase {
        fileprivate let calendar = Calendar.japanese
    }
    struct CumulativePointEntriesCase {
        fileprivate let calendar = Calendar.japanese
    }
}

extension AllUserCumulativeDataTest.MakeCase {

    @Test("単一ユーザーの累計ポイントが日付順に正しく計算される")
    func make_calcsCumulativePoints_forSingleUser() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 22; let april22 = try #require(calendar.date(from: comps))
        comps.day = 25; let april25 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
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
                .generate()
        ]

        // Act
        let result = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Assert
        let elements = try #require(result.list.first).sortedElements
        #expect(elements.count == 3)
        #expect(elements[0].date == april20)
        #expect(elements[0].point.value == 10)
        #expect(elements[1].date == april22)
        #expect(elements[1].point.value == 40)
        #expect(elements[2].date == april25)
        #expect(elements[2].point.value == 60)
    }

    @Test("複数ユーザーの場合、ユーザーごとに独立して累計計算される")
    func make_calcsCumulativePoints_perUserIndependently() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 21; let april21 = try #require(calendar.date(from: comps))
        comps.day = 22; let april22 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [
                        .init(indexedDay: april20, point: .init(value: 10)),
                        .init(indexedDay: april22, point: .init(value: 30))
                    ],
                    userId: "u1",
                    userName: "田中",
                    dateRange: april20...april26,
                    calendar: calendar
                )
                .generate(),
            PointOfWeek
                .make(
                    by: [
                        .init(indexedDay: april21, point: .init(value: 5)),
                        .init(indexedDay: april22, point: .init(value: 15))
                    ],
                    userId: "u2",
                    userName: "佐藤",
                    dateRange: april20...april26,
                    calendar: calendar
                )
                .generate()
        ]

        // Act
        let result = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Assert
        let u1 = try #require(result.list.first { $0.userId == "u1" }).sortedElements
        let u2 = try #require(result.list.first { $0.userId == "u2" }).sortedElements
        #expect(u1.count == 2)
        #expect(u1[0].point.value == 10)
        #expect(u1[1].point.value == 40)
        #expect(u2.count == 2)
        #expect(u2[0].point.value == 5)
        #expect(u2[1].point.value == 20)
    }

    @Test("ポイントデータがない場合は空のelementsが返される")
    func make_returnsEmptyElements_whenNoElements() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        let viewableList: [ViewablePointList] = [
            ViewablePointList(userId: "u1", userName: "田中", total: .init(value: 0), elements: [])
        ]
        _ = april20

        // Act
        let result = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Assert
        let userData = try #require(result.list.first)
        #expect(userData.elements.isEmpty)
        #expect(userData.total.value == 0)
    }
}

extension AllUserCumulativeDataTest.CumulativePointEntriesCase {

    @Test("指定した日付に一致する累計エントリが返される（日粒度）")
    func cumulativePointEntries_returnsMatchingEntries_forDayGranularity() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 22; let april22 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [
                        .init(indexedDay: april20, point: .init(value: 10)),
                        .init(indexedDay: april22, point: .init(value: 30))
                    ],
                    userId: "u1",
                    userName: "田中",
                    dateRange: april20...april26,
                    calendar: calendar
                )
                .generate()
        ]
        let sut = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Act
        let entries = sut.cumulativePointEntries(for: april22, calendar: calendar)

        // Assert
        #expect(entries.count == 1)
        #expect(entries[0].userName == "田中")
        #expect(entries[0].point == 40)
    }

    @Test("データがない日付を指定した場合は空配列が返される")
    func cumulativePointEntries_returnsEmpty_whenNoDataForDate() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4
        comps.day = 20; let april20 = try #require(calendar.date(from: comps))
        comps.day = 23; let april23 = try #require(calendar.date(from: comps))
        comps.day = 26; let april26 = try #require(calendar.date(from: comps))
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [.init(indexedDay: april20, point: .init(value: 10))],
                    userId: "u1",
                    userName: "田中",
                    dateRange: april20...april26,
                    calendar: calendar
                )
                .generate()
        ]
        let sut = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Act
        let entries = sut.cumulativePointEntries(for: april23, calendar: calendar)

        // Assert
        #expect(entries.isEmpty)
    }

    @Test("年間データの場合は月粒度でフィルタリングされる")
    func cumulativePointEntries_filtersWithMonthGranularity_forYearPeriod() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 1; comps.day = 1; let jan1 = try #require(calendar.date(from: comps))
        comps.month = 3; comps.day = 15; let mar15 = try #require(calendar.date(from: comps))
        comps.month = 3; comps.day = 1; let mar1 = try #require(calendar.date(from: comps))
        comps.month = 12; comps.day = 31; let dec31 = try #require(calendar.date(from: comps))
        let viewableList: [ViewablePointList] = [
            PointOfYear
                .make(
                    by: [
                        .init(indexedDay: jan1, point: .init(value: 20)),
                        .init(indexedDay: mar15, point: .init(value: 30))
                    ],
                    userId: "u1",
                    userName: "田中",
                    dateRange: jan1...dec31,
                    calendar: calendar
                )
                .generate()
        ]
        let sut = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .year
        )

        // Act: 3月1日で検索（mar15 と同月）
        let entries = sut.cumulativePointEntries(for: mar1, calendar: calendar)

        // Assert
        #expect(entries.count == 1)
        #expect(entries[0].point == 50)
    }
}
