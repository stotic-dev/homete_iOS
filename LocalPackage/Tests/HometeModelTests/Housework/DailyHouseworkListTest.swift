//
//  DailyHouseworkListTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation
@testable import HometeModel
import Testing

// swiftlint:disable:next convenience_type
enum DailyHouseworkListTest {

    struct MakeInitialValueCase {}
    struct IsRegisteredCase {}

}

extension DailyHouseworkListTest.MakeInitialValueCase {

    @Test("選んだ日の0時を日付にした、家事の無い一日の家事情報を作る")
    func makeInitialValue() {
        // Arrange
        let calendar = Calendar.japanese
        let selectedDate = Date()
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let expectedIndexedDate = HouseworkIndexedDate(value: selectedDay)

        let expectedList = DailyHouseworkList(
            items: [],
            metaData: .init(indexedDate: expectedIndexedDate)
        )

        // Act
        let list = DailyHouseworkList.makeInitialValue(
            selectedDate: selectedDate,
            items: [],
            calendar: calendar
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
            metaData: .init(indexedDate: .init(value: .now))
        )

        // Act
        let result = list.isRegistered

        // Assert
        #expect(result == !inputItems.isEmpty)
    }

}
