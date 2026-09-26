//
//  HouseworkBoardEmptyReasonTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2026/04/04.
//

import Foundation
import HometeDomain
@testable import HouseworkFeature
import Testing

enum HouseworkBoardEmptyReasonTest {

    struct InitWithNoHouseworkRegistered {

        @Test(
            "家事が1件も登録されていない場合はnoHouseworkRegisteredを返す",
            arguments: HouseworkState.allCases
        )
        func returns_noHouseworkRegistered_when_items_is_empty(state: HouseworkState) {
            // Arrange
            let list = HouseworkBoardList(items: [])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: state)

            // Assert
            #expect(actual == .noHouseworkRegistered)
        }

    }

    struct InitWithIncompleteState {

        @Test("フィルタ結果が空でない場合はnilを返す")
        func returns_nil_when_filtered_items_is_not_empty() {
            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForPreview(id: "1", state: .incomplete),
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .incomplete)

            // Assert
            #expect(actual == nil)
        }

        @Test("未完了タブが空で家事が登録されている場合はallCompletedを返す")
        func returns_allCompleted_when_incomplete_is_empty_but_items_exist() {
            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForPreview(id: "1", state: .notTodo),
                .makeForPreview(id: "2", state: .completed),
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .incomplete)

            // Assert
            #expect(actual == .allCompleted)
        }

    }

    struct InitWithCompletedState {

        @Test("完了タブが空で未完了家事がある場合はhasIncompleteHouseworkを返す")
        func returns_hasIncompleteHousework_when_incomplete_exists() {
            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForPreview(id: "1", state: .incomplete),
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .completed)

            // Assert
            #expect(actual == .hasIncompleteHousework)
        }

        @Test("完了タブが空でやらない家事しかない場合もhasIncompleteHouseworkを返す")
        func returns_hasIncompleteHousework_when_only_notTodo_exists() {
            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForPreview(id: "1", state: .notTodo),
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .completed)

            // Assert
            #expect(actual == .hasIncompleteHousework)
        }

        @Test("完了した家事がある場合はnilを返す")
        func returns_nil_when_completed_exists() {
            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForPreview(id: "1", state: .completed),
                .makeForPreview(id: "2", state: .incomplete),
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .completed)

            // Assert
            #expect(actual == nil)
        }

    }

}
