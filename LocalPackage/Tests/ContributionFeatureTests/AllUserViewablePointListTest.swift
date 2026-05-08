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
    struct NearestDateCase {
        private let calendar = Calendar.japanese
    }
}

extension AllUserViewablePointListTest.NearestDateCase {

    @Test("タップ日付に最も近いデータの日付が返る")
    func nearestDate_returnsClosestDataDate() throws {

        // Arrange
        let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
        let april23 = Date.previewDate(year: 2026, month: 4, day: 23)
        let april26 = Date.previewDate(year: 2026, month: 4, day: 26)
        let sut = AllUserViewablePointList(
            list: [
                .init(
                    userId: "u1",
                    userName: "ユーザー1",
                    total: .init(value: 0),
                    elements: [
                        .init(point: .init(value: 10), date: april20),
                        .init(point: .init(value: 20), date: april26)
                    ]
                ),
                .init(
                    userId: "u2",
                    userName: "ユーザー2",
                    total: .init(value: 0),
                    elements: [
                        .init(point: .init(value: 5), date: april23)
                    ]
                )
            ],
            displayPeriod: .week
        )
        let tapDate = Date.previewDate(year: 2026, month: 4, day: 24)

        // Act
        let result = sut.nearestDate(to: tapDate)

        // Assert
        #expect(result == april23)
    }

    @Test("複数ユーザー間でも全データから最も近い日付が返る")
    func nearestDate_picksAcrossUsers() throws {

        // Arrange
        let april20 = Date.previewDate(year: 2026, month: 4, day: 20)
        let april25 = Date.previewDate(year: 2026, month: 4, day: 25)
        let sut = AllUserViewablePointList(
            list: [
                .init(
                    userId: "u1",
                    userName: "ユーザー1",
                    total: .init(value: 0),
                    elements: [.init(point: .init(value: 10), date: april20)]
                ),
                .init(
                    userId: "u2",
                    userName: "ユーザー2",
                    total: .init(value: 0),
                    elements: [.init(point: .init(value: 5), date: april25)]
                )
            ],
            displayPeriod: .week
        )
        let tapDate = Date.previewDate(year: 2026, month: 4, day: 24)

        // Act
        let result = sut.nearestDate(to: tapDate)

        // Assert
        #expect(result == april25)
    }

    @Test("データが空の場合はnilが返る")
    func nearestDate_returnsNilWhenNoData() throws {

        // Arrange
        let sut = AllUserViewablePointList(
            list: [
                .init(userId: "u1", userName: "ユーザー1", total: .init(value: 0), elements: [])
            ],
            displayPeriod: .week
        )
        let tapDate = Date.previewDate(year: 2026, month: 4, day: 23)

        // Act
        let result = sut.nearestDate(to: tapDate)

        // Assert
        #expect(result == nil)
    }
}
