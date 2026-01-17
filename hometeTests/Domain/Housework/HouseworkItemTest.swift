//
//  HouseworkItemTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation
import Testing

@testable import homete

enum HouseworkItemTest {

    struct CanReviewCase {}
}

extension HouseworkItemTest.CanReviewCase {

    @Test(
        "担当者が自分以外かつ未完了の場合、レビュー可能",
        arguments: [HouseworkState.incomplete, .pendingApproval]
    )
    func canReview_notOwnUserAndNotCompleted_returnsTrue(state: HouseworkState) {

        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            state: state,
            executorId: "otherUserId"
        )

        // Act
        let result = item.canReview(ownUserId: "ownUserId")

        // Assert
        #expect(result == true)
    }

    @Test(
        "担当者が自分以外でも完了済みの場合、レビュー不可",
        arguments: ["otherUserId", nil]
    )
    func canReview_completedState_returnsFalse(executorId: String?) {

        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: executorId
        )

        // Act
        let result = item.canReview(ownUserId: "ownUserId")

        // Assert
        #expect(result == false)
    }

    @Test(
        "担当者が自分の場合、未完了でもレビュー不可",
        arguments: HouseworkState.allCases
    )
    func canReview_ownUser_returnsFalse(state: HouseworkState) {

        // Arrange
        let ownUserId = "ownUserId"
        let item = HouseworkItem.makeForTest(
            id: 1,
            state: state,
            executorId: ownUserId
        )

        // Act
        let result = item.canReview(ownUserId: ownUserId)

        // Assert
        #expect(result == false)
    }
}
