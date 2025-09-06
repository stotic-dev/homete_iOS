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
}

extension HouseworkHistoryListTest.MoveToFrontIfExistsCase {
    
    @Test("存在する要素を指定すると先頭へ移動する")
    func moveExistingItemToFront() async throws {
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
    func noChangeWhenItemAlreadyAtFront() async throws {
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
    func noChangeWhenItemDoesNotExist() async throws {
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
