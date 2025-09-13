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
        let items = [
            HouseworkItem(id: "1", title: "洗濯", state: .incomplete),
            HouseworkItem(id: "2", title: "皿洗い", state: .pendingApproval)
        ]
        
        let expectedIndexedDate = calendar.startOfDay(for: selectedDate)
        let expectedExpiredAt = try #require(calendar.date(byAdding: .month, value: 3, to: expectedIndexedDate))
        let expectedList = DailyHouseworkList(
            indexedDate: calendar.startOfDay(for: selectedDate),
            metaData: .init(expiredAt: expectedExpiredAt),
            items: items
        )
        
        // Act
        let list = DailyHouseworkList.makeInitialValue(
            selectedDate: selectedDate,
            items: items,
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
            [HouseworkItem(id: "1", title: "洗濯", state: .incomplete)],
            []
        ]
    )
    func isRegistered(inputItems: [HouseworkItem]) {
        
        // Arrange
        let list = DailyHouseworkList(
            indexedDate: .now,
            metaData: .init(expiredAt: .now),
            items: inputItems
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
            HouseworkItem(id: "1", title: "洗濯", state: .incomplete),
            HouseworkItem(id: "3", title: "洗濯", state: .incomplete),
            HouseworkItem(id: "1", title: "掃除", state: .incomplete)
        ]
    )
    func alreadyRegistered_trueWhenSameTitleExists(inputItem: HouseworkItem) {
        
        // Arrange
        let items: [HouseworkItem] = [
            .init(id: "1", title: "洗濯", state: .incomplete),
            .init(id: "2", title: "ゴミ捨て", state: .completed)
        ]
        let list = DailyHouseworkList(
            indexedDate: .now,
            metaData: .init(expiredAt: .now),
            items: items
        )
        
        // Act
        let result = list.isAlreadyRegistered(inputItem)
        
        // Assert
        let expected = items.contains { $0.title == inputItem.title }
        #expect(result == expected)
    }
}
