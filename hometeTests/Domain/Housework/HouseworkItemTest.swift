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
    struct UpdateStateCase {}
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

// MARK: - UpdateStateCase

extension HouseworkItemTest.UpdateStateCase {

    @Test("承認待ち状態に更新すると、state・executorId・executedAtが更新される")
    func updatePendingApproval_updatesStateAndExecutorInfo() {

        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .incomplete,
            expiredAt: expiredAt
        )
        let now = Date()
        let changerId = "changerId"

        // Act
        let result = item.updatePendingApproval(at: now, changer: changerId)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .pendingApproval,
            executorId: changerId,
            executedAt: now,
            expiredAt: expiredAt
        )
        #expect(result == expected)
    }
    
    @Test("承認すると、state・reviewerId・approvedAt・reviewerCommentが更新される")
    func updateApproved_updatesStateAndReviewerInfo() {

        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let executorId = "executorId"
        let executedAt = Date().addingTimeInterval(-3600)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .pendingApproval,
            executorId: executorId,
            executedAt: executedAt,
            expiredAt: expiredAt
        )
        let now = Date()
        let reviewerId = "reviewerId"
        let comment = "よくできました"

        // Act
        let result = item.updateApproved(at: now, reviewer: reviewerId, comment: comment)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .completed,
            executorId: executorId,
            executedAt: executedAt,
            reviewerId: reviewerId,
            approvedAt: now,
            reviewerComment: comment,
            expiredAt: expiredAt
        )
        #expect(result == expected)
    }
    
    @Test("未完了状態に戻すと、stateがincompleteになり実行者・承認者情報がクリアされる")
    func updateIncomplete_clearsExecutorAndReviewerInfo() {

        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .completed,
            executorId: "executorId",
            executedAt: Date(),
            reviewerId: "reviewerId",
            approvedAt: Date(),
            reviewerComment: "コメント",
            expiredAt: expiredAt
        )

        // Act
        let result = item.updateIncomplete()

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .incomplete,
            expiredAt: expiredAt
        )
        #expect(result == expected)
    }
}
