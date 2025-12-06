//
//  DailyHouseworkListTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation
import Testing

@testable import homete

// swiftlint:disable:next convenience_type
struct DailyHouseworkListTest {
    
    struct MakeInitialValueCase {}
    struct IsRegisteredCase {}
    struct IsAlreadyRegisteredCase {}
}

extension DailyHouseworkListTest.MakeInitialValueCase {
    
    @Test("一日の家事情報の保持期限は3か月後になる")
    func makeInitialValue() throws {
        
        // Arrange
        let calendar = Calendar(identifier: .gregorian)
        let selectedDate = Date()
        let expectedIndexedDate = HouseworkIndexedDate(selectedDate)
        let expectedExpiredAt = try #require(calendar.date(byAdding: .month, value: 1, to: selectedDate))
        
        let expectedList = DailyHouseworkList(
            items: [],
            metaData: .init(indexedDate: expectedIndexedDate, expiredAt: expectedExpiredAt)
        )
        
        // Act
        let list = DailyHouseworkList.makeInitialValue(
            selectedDate: selectedDate,
            items: [],
            calendar: calendar,
            locale: .jp
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
            []
        ]
    )
    func isRegistered(inputItems: [HouseworkItem]) {
        
        // Arrange
        let list = DailyHouseworkList(
            items: inputItems,
            metaData: .init(indexedDate: .init(.now), expiredAt: .now)
        )
        
        // Act
        let result = list.isRegistered
        
        // Assert
        #expect(result == !inputItems.isEmpty)
    }
}

extension DailyHouseworkListTest.IsAlreadyRegisteredCase {
    
    @Test(
        "同じタイトルの家事が含まれていれば登録済みの家事とみなす",
        arguments: [
            HouseworkItem.makeForTest(id: 1, title: "洗濯", point: 1),
            .makeForTest(id: 3, title: "洗濯", point: 1),
            .makeForTest(id: 1, title: "掃除", point: 1)
        ]
    )
    func alreadyRegistered_trueWhenSameTitleExists(inputItem: HouseworkItem) {
        
        // Arrange
        let items: [HouseworkItem] = [
            .makeForTest(id: 1, title: "洗濯", point: 1),
            .makeForTest(id: 2, title: "ゴミ捨て", point: 1, state: .completed)
        ]
        let list = DailyHouseworkList(
            items: items,
            metaData: .init(indexedDate: .init(.now), expiredAt: .now)
        )
        
        // Act
        let result = list.isAlreadyRegistered(inputItem)
        
        // Assert
        let expected = items.contains { $0.title == inputItem.title }
        #expect(result == expected)
    }
}
