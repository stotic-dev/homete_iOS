//
//  HouseworkBoardItemTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/20.
//

@testable import HometeDomain
@testable import HouseworkFeature
import Testing

// swiftlint:disable:next convenience_type
enum HouseworkBoardItemTest {

    struct CanReviewCase {}

}

extension HouseworkBoardItemTest.CanReviewCase {

    @Test(
        "担当者が自分以外かつ未完了の場合、レビュー可能",
        arguments: [HouseworkState.incomplete, .pendingApproval]
    )
    func canReview_notOwnUserAndNotCompleted_returnsTrue(state: HouseworkState) {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
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
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
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
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: state,
            executorId: ownUserId
        )

        // Act
        let result = item.canReview(ownUserId: ownUserId)

        // Assert
        #expect(result == false)
    }

}
