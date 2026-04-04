//
//  HouseworkBoardEmptyReasonTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2026/04/04.
//

import Foundation
import Testing

@testable import HometeDomain

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
            let actual = HouseworkBoardEmptyReason(list: list, state: state, ownUserId: "user1")

            // Assert
            #expect(actual == .noHouseworkRegistered)
        }
    }

    struct InitWithIncompleteState {

        @Test("フィルタ結果が空でない場合はnilを返す")
        func returns_nil_when_filtered_items_is_not_empty() {

            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForTest(id: 1, state: .incomplete)
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .incomplete, ownUserId: "user1")

            // Assert
            #expect(actual == nil)
        }

        @Test("未完了タブが空で家事が登録されている場合はallCompletedOrPendingを返す")
        func returns_allCompletedOrPending_when_incomplete_is_empty_but_items_exist() {

            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForTest(id: 1, state: .pendingApproval),
                .makeForTest(id: 2, state: .completed)
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .incomplete, ownUserId: "user1")

            // Assert
            #expect(actual == .allCompletedOrPending)
        }
    }

    struct InitWithPendingApprovalState {

        @Test("承認待ちタブが空で未完了の家事がある場合はnoPendingApproval(hasIncomplete: true)を返す")
        func returns_noPendingApproval_hasIncomplete_true_when_incomplete_exists() {

            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForTest(id: 1, state: .incomplete),
                .makeForTest(id: 2, state: .completed)
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .pendingApproval, ownUserId: "user1")

            // Assert
            #expect(actual == .noPendingApproval(hasIncomplete: true))
        }

        @Test("承認待ちタブが空で未完了の家事もない場合はnoPendingApproval(hasIncomplete: false)を返す")
        func returns_noPendingApproval_hasIncomplete_false_when_incomplete_not_exists() {

            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForTest(id: 1, state: .completed)
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .pendingApproval, ownUserId: "user1")

            // Assert
            #expect(actual == .noPendingApproval(hasIncomplete: false))
        }
    }

    struct InitWithCompletedState {

        @Test("完了タブが空で自身が承認できる承認待ち家事がある場合はcanReviewPendingApprovalを返す")
        func returns_canReviewPendingApproval_when_reviewable_pending_exists() {

            // Arrange
            // executorId が ownUserId と異なる → canReview = true
            let list = HouseworkBoardList(items: [
                .makeForTest(id: 1, state: .pendingApproval, executorId: "other")
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .completed, ownUserId: "user1")

            // Assert
            #expect(actual == .canReviewPendingApproval)
        }

        @Test("完了タブが空で承認待ち家事が全て自分が実行したものの場合はallPendingApprovalByOthersを返す")
        func returns_allPendingApprovalByOthers_when_all_pending_are_own() {

            // Arrange
            // executorId が ownUserId と同じ → canReview = false
            let list = HouseworkBoardList(items: [
                .makeForTest(id: 1, state: .pendingApproval, executorId: "user1"),
                .makeForTest(id: 2, state: .pendingApproval, executorId: "user1")
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .completed, ownUserId: "user1")

            // Assert
            #expect(actual == .allPendingApprovalByOthers)
        }

        @Test("完了タブが空で承認待ちがなく未完了家事がある場合はhasIncompleteHouseworkを返す")
        func returns_hasIncompleteHousework_when_no_pending_but_incomplete_exists() {

            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForTest(id: 1, state: .incomplete)
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .completed, ownUserId: "user1")

            // Assert
            #expect(actual == .hasIncompleteHousework)
        }

        @Test("完了タブが空で承認待ちと未完了が混在する場合はcanReviewPendingApprovalが優先される")
        func returns_canReviewPendingApproval_when_both_pending_and_incomplete_exist() {

            // Arrange
            let list = HouseworkBoardList(items: [
                .makeForTest(id: 1, state: .pendingApproval, executorId: "other"),
                .makeForTest(id: 2, state: .incomplete)
            ])

            // Act
            let actual = HouseworkBoardEmptyReason(list: list, state: .completed, ownUserId: "user1")

            // Assert
            #expect(actual == .canReviewPendingApproval)
        }
    }
}
