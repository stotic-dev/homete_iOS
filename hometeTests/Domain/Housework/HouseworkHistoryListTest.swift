//
//  HouseworkHistoryListTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import Testing
@testable import homete

// swiftlint:disable:next convenience_type
struct HouseworkHistoryListTest {
    
    struct MoveToFrontIfExistsCase {}
    struct AddNewHistoryCase {}
}

extension HouseworkHistoryListTest.MoveToFrontIfExistsCase {
    
    @Test("存在する要素を指定すると先頭へ移動する")
    func moveExistingItemToFront() {
        
        // Arrange
        var list = HouseworkHistoryList(items: ["1", "2", "3"])
        let target = "2"
        let expected = HouseworkHistoryList(items: ["2", "1", "3"])

        // Act
        list.moveToFrontIfExists(target)

        // Assert
        #expect(list == expected)
    }

    @Test("既に先頭の要素を指定しても変更されない")
    func noChangeWhenItemAlreadyAtFront() {
        
        // Arrange
        let initial = HouseworkHistoryList(items: ["a", "b", "c"])
        var list = initial
        let target = "a"

        // Act
        list.moveToFrontIfExists(target)

        // Assert
        #expect(list == initial)
    }

    @Test("存在しない要素を指定しても変更されない")
    func noChangeWhenItemDoesNotExist() {
        
        // Arrange
        let initial = HouseworkHistoryList(items: ["x", "y", "z"])
        var list = initial
        let target = "w"

        // Act
        list.moveToFrontIfExists(target)

        // Assert
        #expect(list == initial)
    }
}

extension HouseworkHistoryListTest.AddNewHistoryCase {
    
    @Test(
        "履歴に存在しない要素を追加する場合、その要素が先頭に追加される",
        arguments: [
            ["洗濯", "皿洗い"],
            []
        ]
    )
    func addNewItem(initialList: [String]) {
        
        // Arrange
        let value = "掃除"
        var list = HouseworkHistoryList(items: initialList)
        let expected = HouseworkHistoryList(items: ["掃除"] + initialList)
        
        // Act
        list.addNewHistory(value)
        
        // Assert
        #expect(list == expected)
    }
    
    @Test("既に存在する要素を追加する場合、リストは変更されない")
    func addValueAlreadyAtFrontDoesNotChange() {
        
        // Arrange
        let initial = HouseworkHistoryList(items: ["洗濯", "掃除", "皿洗い"])
        var list = initial
        let value = "掃除"
        
        // Act
        list.addNewHistory(value)
        
        // Assert
        let expected = HouseworkHistoryList(items: ["掃除", "洗濯", "皿洗い"])
        #expect(list == expected)
    }
}
