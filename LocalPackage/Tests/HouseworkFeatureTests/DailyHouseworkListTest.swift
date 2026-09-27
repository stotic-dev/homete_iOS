//
//  DailyHouseworkListTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation
import HometeDomain
@testable import HouseworkFeature
import Testing

// swiftlint:disable:next convenience_type
enum DailyHouseworkListTest {

    struct MakeInitialValueCase {}
    struct IsRegisteredCase {}

}

extension DailyHouseworkListTest.MakeInitialValueCase {

    @Test("無料プランでは一日の家事情報の保持期限は1年後になる")
    func makeInitialValueWithFreePlan() throws {
        // Arrange
        let calendar = Calendar.japanese
        let selectedDate = Date()
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let expectedIndexedDate = HouseworkIndexedDate(value: selectedDay)
        let expectedExpiredAt = try #require(calendar.date(byAdding: .year, value: 1, to: selectedDay))

        let expectedList = DailyHouseworkList(
            items: [],
            metaData: .init(indexedDate: expectedIndexedDate, expiredAt: expectedExpiredAt)
        )

        // Act
        let list = DailyHouseworkList.makeInitialValue(
            selectedDate: selectedDate,
            items: [],
            calendar: calendar,
            storagePolicy: .free
        )

        // Assert
        #expect(list == expectedList)
    }

    @Test("プレミアムプランでは一日の家事情報の保持期限は100年後になる")
    func makeInitialValueWithPremiumPlan() throws {
        // Arrange
        let calendar = Calendar.japanese
        let selectedDate = Date()
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let expectedIndexedDate = HouseworkIndexedDate(value: selectedDay)
        let expectedExpiredAt = try #require(calendar.date(byAdding: .year, value: 100, to: selectedDay))

        let expectedList = DailyHouseworkList(
            items: [],
            metaData: .init(indexedDate: expectedIndexedDate, expiredAt: expectedExpiredAt)
        )

        // Act
        let list = DailyHouseworkList.makeInitialValue(
            selectedDate: selectedDate,
            items: [],
            calendar: calendar,
            storagePolicy: .premium
        )

        // Assert
        #expect(list == expectedList)
    }

}

extension DailyHouseworkListTest.IsRegisteredCase {

    @Test(
        "登録されている家事がない場合は、その日付の家事レコードが登録されていない",
        arguments: [
            [HouseworkItem.makeForTest(id: 1, title: "洗濯", point: 1)],
            [],
        ]
    )
    func isRegistered(inputItems: [HouseworkItem]) {
        // Arrange
        let list = DailyHouseworkList(
            items: inputItems,
            metaData: .init(indexedDate: .init(value: .now), expiredAt: .now)
        )

        // Act
        let result = list.isRegistered

        // Assert
        #expect(result == !inputItems.isEmpty)
    }

}
