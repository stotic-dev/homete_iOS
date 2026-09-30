//
//  HouseworkHistoryListTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/07.
//

@testable import HometeDomain
import Testing

// swiftlint:disable:next convenience_type
enum HouseworkHistoryListTest {

    struct MoveToFrontIfExistsCase {}
    struct AddNewHistoryCase {}

}

extension HouseworkHistoryListTest.MoveToFrontIfExistsCase {

    @Test("存在する名前を指定すると、その履歴がポイントごと先頭へ移動する")
    func moveExistingItemToFront() {
        // Arrange
        var list = HouseworkHistoryList(items: [
            .init(title: "洗濯", point: 10),
            .init(title: "掃除", point: 20),
            .init(title: "皿洗い", point: 30),
        ])
        let target = "掃除"
        let expected = HouseworkHistoryList(items: [
            .init(title: "掃除", point: 20),
            .init(title: "洗濯", point: 10),
            .init(title: "皿洗い", point: 30),
        ])

        // Act
        list.moveToFrontIfExists(target)

        // Assert
        #expect(list == expected)
    }

    @Test("既に先頭の名前を指定しても変更されない")
    func noChangeWhenItemAlreadyAtFront() {
        // Arrange
        let initial = HouseworkHistoryList(items: [
            .init(title: "洗濯", point: 10),
            .init(title: "掃除", point: 20),
        ])
        var list = initial
        let target = "洗濯"

        // Act
        list.moveToFrontIfExists(target)

        // Assert
        #expect(list == initial)
    }

    @Test("存在しない名前を指定しても変更されない")
    func noChangeWhenItemDoesNotExist() {
        // Arrange
        let initial = HouseworkHistoryList(items: [
            .init(title: "洗濯", point: 10),
            .init(title: "掃除", point: 20),
        ])
        var list = initial
        let target = "ゴミ出し"

        // Act
        list.moveToFrontIfExists(target)

        // Assert
        #expect(list == initial)
    }

}

extension HouseworkHistoryListTest.AddNewHistoryCase {

    @Test(
        "履歴に存在しない家事を追加する場合、その家事が先頭に追加される",
        arguments: [
            [HouseworkEntryHistoryItem(title: "洗濯", point: 10), .init(title: "皿洗い", point: 20)],
            [],
        ]
    )
    func addNewItem(initialList: [HouseworkEntryHistoryItem]) {
        // Arrange
        let value = HouseworkEntryHistoryItem(title: "掃除", point: 30)
        var list = HouseworkHistoryList(items: initialList)
        let expected = HouseworkHistoryList(items: [.init(title: "掃除", point: 30)] + initialList)

        // Act
        list.addNewHistory(value)

        // Assert
        #expect(list == expected)
    }

    @Test("既に存在する名前を追加する場合、その履歴が先頭へ移動する")
    func addValueAlreadyExistsMovesToFront() {
        // Arrange
        var list = HouseworkHistoryList(items: [
            .init(title: "洗濯", point: 10),
            .init(title: "掃除", point: 20),
            .init(title: "皿洗い", point: 30),
        ])
        let value = HouseworkEntryHistoryItem(title: "掃除", point: 20)

        // Act
        list.addNewHistory(value)

        // Assert
        let expected = HouseworkHistoryList(items: [
            .init(title: "掃除", point: 20),
            .init(title: "洗濯", point: 10),
            .init(title: "皿洗い", point: 30),
        ])
        #expect(list == expected)
    }

    @Test("既に存在する名前を違うポイントで追加する場合、ポイントが新しいものに置き換わる")
    func addValueAlreadyExistsUpdatesPoint() {
        // Arrange
        var list = HouseworkHistoryList(items: [
            .init(title: "洗濯", point: 10),
            .init(title: "掃除", point: 20),
        ])
        let value = HouseworkEntryHistoryItem(title: "掃除", point: 50)

        // Act
        list.addNewHistory(value)

        // Assert
        let expected = HouseworkHistoryList(items: [
            .init(title: "掃除", point: 50),
            .init(title: "洗濯", point: 10),
        ])
        #expect(list == expected)
    }

}
