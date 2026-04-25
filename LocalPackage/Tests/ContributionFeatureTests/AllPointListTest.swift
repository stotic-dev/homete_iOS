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
        private let calendar = Calendar.japanese
    }
}

extension AllPointListTest.MakeCase {

    @Test("完了した家事のみ獲得ポイントとして集計される")
    func make_onlyCompletedItemsAreIncluded() {

        // Arrange
        let inputFirstDate = Date.previewDate(year: 2026, month: 1, day: 1)
        let inputSecondDate = Date.previewDate(year: 2026, month: 1, day: 2)
        let inputThirdDate = Date.previewDate(year: 2026, month: 1, day: 3)
        let items: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: inputFirstDate, point: 30, state: .completed),
            .makeForTest(id: 2, indexedDate: inputSecondDate, point: 50, state: .incomplete),
            .makeForTest(id: 3, indexedDate: inputThirdDate, point: 20, state: .completed)
        ]

        // Act
        let result = AllPointList.make(by: items, calendar: calendar)

        // Assert
        let expectedList: [PointOfDay] = [
            .init(indexedDay: inputFirstDate, point: .init(value: 30)),
            .init(indexedDay: inputThirdDate, point: .init(value: 20))
        ]
        #expect(result == .init(list: expectedList))
    }

    @Test("家事が空の場合は空のリストが返る")
    func make_emptyInput_returnsEmptyList() {

        // Arrange
        let items: [HouseworkItem] = []

        // Act
        let result = AllPointList.make(by: items, calendar: calendar)

        // Assert
        #expect(result == .init(list: []))
    }
}
