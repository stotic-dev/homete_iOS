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
    struct MakeCase {}
    struct CumulativePointEntriesCase {}
}

extension AllUserCumulativeDataTest.MakeCase {
    
    static let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
    static let april21 = Date.previewDate(year: 2026, month: 4, day: 21)
    static let april22 = Date.previewDate(year: 2026, month: 4, day: 22)
    static let april23 = Date.previewDate(year: 2026, month: 4, day: 23)
    static let april24 = Date.previewDate(year: 2026, month: 4, day: 24)
    static let april25 = Date.previewDate(year: 2026, month: 4, day: 25)
    static let april26 = Date.previewDate(year: 2026, month: 4, day: 26)
    
    static let userId1 = "u1"
    static let userName1 = "田中"
    static let userId2 = "u2"
    static let userName2 = "鈴木"

    @Test("単一ユーザーの累計ポイントが日付順に正しく計算される")
    func make_calcsCumulativePoints_forSingleUser() throws {

        // Arrange
        let weekDates: [Date] = (20...26).map {
            Date.previewDate(year: 2026, month: 4, day: $0)
        }
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [
                        Self.april20: .init(indexedDay: Self.april20, point: .init(value: 10)),
                        Self.april22: .init(indexedDay: Self.april22, point: .init(value: 30)),
                        Self.april25: .init(indexedDay: Self.april25, point: .init(value: 20))
                    ],
                    userId: Self.userId1,
                    userName: Self.userName1,
                    dates: weekDates,
                    calendar: .japanese
                )
                .generate()
        ]

        // Act
        let result = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Assert
        let expected = AllUserCumulativeData(
            list: [
                .init(
                    userId: Self.userId1,
                    userName: Self.userName1,
                    total: .init(value: 60),
                    elements: [
                        .init(point: .init(value: 10), date: Self.april20),
                        .init(point: .init(value: 10), date: Self.april21),
                        .init(point: .init(value: 40), date: Self.april22),
                        .init(point: .init(value: 40), date: Self.april23),
                        .init(point: .init(value: 40), date: Self.april24),
                        .init(point: .init(value: 60), date: Self.april25),
                        .init(point: .init(value: 60), date: Self.april26)
                    ]
                )
            ],
            displayPeriod: .week
        )
        #expect(result == expected)
    }

    @Test("複数ユーザーの場合、ユーザーごとに独立して累計計算される")
    // swiftlint:disable:next function_body_length
    func make_calcsCumulativePoints_perUserIndependently() throws {

        // Arrange
        let weekDates: [Date] = (20...26).map {
            Date.previewDate(year: 2026, month: 4, day: $0)
        }
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [
                        Self.april20: .init(indexedDay: Self.april20, point: .init(value: 10)),
                        Self.april22: .init(indexedDay: Self.april22, point: .init(value: 30))
                    ],
                    userId: Self.userId1,
                    userName: Self.userName1,
                    dates: weekDates,
                    calendar: .japanese
                )
                .generate(),
            PointOfWeek
                .make(
                    by: [
                        Self.april21: .init(indexedDay: Self.april21, point: .init(value: 5)),
                        Self.april22: .init(indexedDay: Self.april22, point: .init(value: 15))
                    ],
                    userId: Self.userId2,
                    userName: Self.userName2,
                    dates: weekDates,
                    calendar: .japanese
                )
                .generate()
        ]

        // Act
        let result = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Assert
        let expected = AllUserCumulativeData(
            list: [
                .init(
                    userId: Self.userId1,
                    userName: Self.userName1,
                    total: .init(value: 40),
                    elements: [
                        .init(point: .init(value: 10), date: Self.april20),
                        .init(point: .init(value: 10), date: Self.april21),
                        .init(point: .init(value: 40), date: Self.april22),
                        .init(point: .init(value: 40), date: Self.april23),
                        .init(point: .init(value: 40), date: Self.april24),
                        .init(point: .init(value: 40), date: Self.april25),
                        .init(point: .init(value: 40), date: Self.april26)
                    ]
                ),
                .init(
                    userId: Self.userId2,
                    userName: Self.userName2,
                    total: .init(value: 20),
                    elements: [
                        .init(point: .init(value: 0), date: Self.april20),
                        .init(point: .init(value: 5), date: Self.april21),
                        .init(point: .init(value: 20), date: Self.april22),
                        .init(point: .init(value: 20), date: Self.april23),
                        .init(point: .init(value: 20), date: Self.april24),
                        .init(point: .init(value: 20), date: Self.april25),
                        .init(point: .init(value: 20), date: Self.april26)
                    ]
                )
            ],
            displayPeriod: .week
        )
        #expect(result == expected)
    }
}

extension AllUserCumulativeDataTest.CumulativePointEntriesCase {

    static let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
    static let april22 = Date.previewDate(year: 2026, month: 4, day: 22)
    static let april23 = Date.previewDate(year: 2026, month: 4, day: 23)

    static let jan1 = Date.previewDate(year: 2026, month: 1, day: 1)
    static let mar1 = Date.previewDate(year: 2026, month: 3, day: 1)
    static let mar15 = Date.previewDate(year: 2026, month: 3, day: 15)

    static let userId1 = "u1"
    static let userName1 = "田中"

    @Test("指定した日付に一致する累計エントリが返される（日粒度）")
    func cumulativePointEntries_returnsMatchingEntries_forDayGranularity() throws {

        // Arrange
        let weekDates: [Date] = (20...26).map {
            Date.previewDate(year: 2026, month: 4, day: $0)
        }
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [
                        Self.april20: .init(indexedDay: Self.april20, point: .init(value: 10)),
                        Self.april22: .init(indexedDay: Self.april22, point: .init(value: 30))
                    ],
                    userId: Self.userId1,
                    userName: Self.userName1,
                    dates: weekDates,
                    calendar: .japanese
                )
                .generate()
        ]
        let sut = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Act
        let entries = sut.cumulativePointEntries(for: Self.april22, calendar: .japanese)

        // Assert
        let expected: [PointEntry] = [
            .init(id: Self.userId1, userName: Self.userName1, point: 40)
        ]
        #expect(entries == expected)
    }

    @Test("データがない日付を指定した場合は補完値（直前までの累計）が返される")
    func cumulativePointEntries_returnsCarriedOverValue_whenNoDataForDate() throws {

        // Arrange: april20 のみデータがある状態で、補完日(april23)を問い合わせる
        let weekDates: [Date] = (20...26).map {
            Date.previewDate(year: 2026, month: 4, day: $0)
        }
        let viewableList: [ViewablePointList] = [
            PointOfWeek
                .make(
                    by: [Self.april20: .init(indexedDay: Self.april20, point: .init(value: 10))],
                    userId: Self.userId1,
                    userName: Self.userName1,
                    dates: weekDates,
                    calendar: .japanese
                )
                .generate()
        ]
        let sut = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .week
        )

        // Act
        let entries = sut.cumulativePointEntries(for: Self.april23, calendar: .japanese)

        // Assert: 補完日も累計エントリとして返り、値は直前までの累計（10）が引き継がれる
        let expected: [PointEntry] = [
            .init(id: Self.userId1, userName: Self.userName1, point: 10)
        ]
        #expect(entries == expected)
    }

    @Test("年間データの場合は月粒度でフィルタリングされる")
    func cumulativePointEntries_filtersWithMonthGranularity_forYearPeriod() throws {

        // Arrange
        let yearDates: [Date] = (1...12).map {
            Date.previewDate(year: 2026, month: $0, day: 1)
        }
        let viewableList: [ViewablePointList] = [
            PointOfYear
                .make(
                    by: [
                        Self.jan1: .init(indexedDay: Self.jan1, point: .init(value: 20)),
                        Self.mar15: .init(indexedDay: Self.mar15, point: .init(value: 30))
                    ],
                    userId: Self.userId1,
                    userName: Self.userName1,
                    dates: yearDates,
                    calendar: .japanese
                )
                .generate()
        ]
        let sut = AllUserCumulativeData.make(
            list: viewableList,
            displayPeriod: .year
        )

        // Act: 3月1日で検索（mar15 と同月）
        let entries = sut.cumulativePointEntries(for: Self.mar1, calendar: .japanese)

        // Assert
        let expected: [PointEntry] = [
            .init(id: Self.userId1, userName: Self.userName1, point: 50)
        ]
        #expect(entries == expected)
    }
}
