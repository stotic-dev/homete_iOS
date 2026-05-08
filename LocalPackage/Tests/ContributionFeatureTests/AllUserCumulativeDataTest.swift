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
        let weekDates: [Date] = (20...26).map {
            Date.previewDate(year: 2026, month: 4, day: $0)
        }
        let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
        let april22 = Date.previewDate(year: 2026, month: 4, day: 22)
        let april25 = Date.previewDate(year: 2026, month: 4, day: 25)
        let april26 = Date.previewDate(year: 2026, month: 4, day: 26)
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
                    dates: weekDates,
                    calendar: calendar
                )
                .generate()
        ]

        // Act
        let result = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Assert: 補完含む日付ごとの累計が日付順に積み上がる
        let elements = try #require(result.list.first).sortedElements
        #expect(elements.count == weekDates.count)
        let pointAt: (Date) -> Int? = { date in
            elements.first { $0.date == date }?.point.value
        }
        #expect(pointAt(april20) == 10)
        #expect(pointAt(april22) == 40)
        #expect(pointAt(april25) == 60)
        #expect(pointAt(april26) == 60)
    }

    @Test("複数ユーザーの場合、ユーザーごとに独立して累計計算される")
    func make_calcsCumulativePoints_perUserIndependently() throws {

        // Arrange
        let weekDates: [Date] = (20...26).map {
            Date.previewDate(year: 2026, month: 4, day: $0)
        }
        let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
        let april21 = Date.previewDate(year: 2026, month: 4, day: 21)
        let april22 = Date.previewDate(year: 2026, month: 4, day: 22)
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [
                        .init(indexedDay: april20, point: .init(value: 10)),
                        .init(indexedDay: april22, point: .init(value: 30))
                    ],
                    userId: "u1",
                    userName: "田中",
                    dates: weekDates,
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
                    dates: weekDates,
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
        #expect(u1.count == weekDates.count)
        #expect(u2.count == weekDates.count)
        let u1At: (Date) -> Int? = { date in u1.first { $0.date == date }?.point.value }
        let u2At: (Date) -> Int? = { date in u2.first { $0.date == date }?.point.value }
        #expect(u1At(april20) == 10)
        #expect(u1At(april22) == 40)
        #expect(u2At(april21) == 5)
        #expect(u2At(april22) == 20)
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
        let weekDates: [Date] = (20...26).map {
            Date.previewDate(year: 2026, month: 4, day: $0)
        }
        let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
        let april22 = Date.previewDate(year: 2026, month: 4, day: 22)
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [
                        .init(indexedDay: april20, point: .init(value: 10)),
                        .init(indexedDay: april22, point: .init(value: 30))
                    ],
                    userId: "u1",
                    userName: "田中",
                    dates: weekDates,
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

    @Test("データがない日付を指定した場合は補完値（直前までの累計）が返される")
    func cumulativePointEntries_returnsCarriedOverValue_whenNoDataForDate() throws {

        // Arrange: april20 のみデータがある状態で、補完日(april23)を問い合わせる
        let weekDates: [Date] = (20...26).map {
            Date.previewDate(year: 2026, month: 4, day: $0)
        }
        let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
        let april23 = Date.previewDate(year: 2026, month: 4, day: 23)
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [.init(indexedDay: april20, point: .init(value: 10))],
                    userId: "u1",
                    userName: "田中",
                    dates: weekDates,
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

        // Assert: 補完日も累計エントリとして返り、値は直前までの累計（10）が引き継がれる
        #expect(entries.count == 1)
        #expect(entries[0].point == 10)
    }

    @Test("年間データの場合は月粒度でフィルタリングされる")
    func cumulativePointEntries_filtersWithMonthGranularity_forYearPeriod() throws {

        // Arrange
        let yearDates: [Date] = (1...12).map {
            Date.previewDate(year: 2026, month: $0, day: 1)
        }
        let jan1 = Date.previewDate(year: 2026, month: 1, day: 1)
        let mar15 = Date.previewDate(year: 2026, month: 3, day: 15)
        let mar1 = Date.previewDate(year: 2026, month: 3, day: 1)
        let viewableList: [ViewablePointList] = [
            PointOfYear
                .make(
                    by: [
                        .init(indexedDay: jan1, point: .init(value: 20)),
                        .init(indexedDay: mar15, point: .init(value: 30))
                    ],
                    userId: "u1",
                    userName: "田中",
                    dates: yearDates,
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
