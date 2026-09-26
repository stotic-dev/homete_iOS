//
//  HouseworkBoardItemTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/20.
//

@testable import HometeDomain
@testable import HouseworkFeature
import Testing

enum HouseworkBoardItemTest {

    struct CanSendThanksCase {}

}

extension HouseworkBoardItemTest.CanSendThanksCase {

    @Test(
        "完了済みで実施者が自分以外の場合、ありがとうを伝えられる",
        arguments: ["otherUserId", nil]
    )
    func canSendThanks_completedByOtherUser_returnsTrue(executorId: String?) {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: executorId
        )

        // Act
        let result = item.canSendThanks(ownUserId: "ownUserId")

        // Assert
        #expect(result == true)
    }

    @Test(
        "完了していない家事には、ありがとうを伝えられない",
        arguments: [HouseworkState.incomplete, .notTodo]
    )
    func canSendThanks_notCompletedState_returnsFalse(state: HouseworkState) {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: state,
            executorId: "otherUserId"
        )

        // Act
        let result = item.canSendThanks(ownUserId: "ownUserId")

        // Assert
        #expect(result == false)
    }

    @Test(
        "実施者が自分の場合、完了済みでもありがとうを伝えられない",
        arguments: HouseworkState.allCases
    )
    func canSendThanks_ownUser_returnsFalse(state: HouseworkState) {
        // Arrange
        let ownUserId = "ownUserId"
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: state,
            executorId: ownUserId
        )

        // Act
        let result = item.canSendThanks(ownUserId: ownUserId)

        // Assert
        #expect(result == false)
    }

}
