//
//  HouseworkBoardItemTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/20.
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

enum HouseworkBoardItemTest {

    struct CanSendThanksCase {}
    struct CanEditThanksCase {}

}

extension HouseworkBoardItemTest.CanSendThanksCase {

    @Test("完了済みで担当者が自分以外の場合、ありがとうを伝えられる")
    func canSendThanks_completedByOtherUser_returnsTrue() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId"
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
        "担当者が自分だけの場合、完了済みでもありがとうを伝えられない",
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

    @Test("自分を含む複数人で担当した家事は、他の担当者へありがとうを伝えられる")
    func canSendThanks_sharedWithOwnUser_returnsTrue() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            point: 10,
            state: .completed,
            executors: [
                .init(userId: "ownUserId", percentage: 50, point: 5),
                .init(userId: "otherUserId", percentage: 50, point: 5),
            ]
        )

        // Act
        let result = item.canSendThanks(ownUserId: "ownUserId")

        // Assert
        #expect(result == true)
    }

    @Test("担当者のいない完了済みの家事には、ありがとうを伝えられない")
    func canSendThanks_noExecutor_returnsFalse() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed
        )

        // Act
        let result = item.canSendThanks(ownUserId: "ownUserId")

        // Assert
        #expect(result == false)
    }

    @Test("自分以外が実施した家事でも、すでにありがとうを送っていれば、もう一度は伝えられない")
    func canSendThanks_alreadySent_returnsFalse() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId",
            thanks: ["ownUserId": .init(comment: nil, sentAt: .distantPast)]
        )

        // Act
        let result = item.canSendThanks(ownUserId: "ownUserId")

        // Assert
        #expect(result == false)
    }

    @Test("ほかの人がありがとうを送っていても、自分がまだ送っていなければ伝えられる")
    func canSendThanks_sentByAnotherUser_returnsTrue() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId",
            thanks: ["anotherUserId": .init(comment: nil, sentAt: .distantPast)]
        )

        // Act
        let result = item.canSendThanks(ownUserId: "ownUserId")

        // Assert
        #expect(result == true)
    }

}

extension HouseworkBoardItemTest.CanEditThanksCase {

    @Test("自分が送ったありがとうがある場合、コメントを編集できる")
    func canEditThanks_alreadySent_returnsTrue() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId",
            thanks: ["ownUserId": .init(comment: nil, sentAt: .distantPast)]
        )

        // Act
        let result = item.canEditThanks(ownUserId: "ownUserId")

        // Assert
        #expect(result == true)
    }

    @Test("自分がまだありがとうを送っていない場合、編集はできない")
    func canEditThanks_notSent_returnsFalse() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId",
            thanks: ["anotherUserId": .init(comment: nil, sentAt: .distantPast)]
        )

        // Act
        let result = item.canEditThanks(ownUserId: "ownUserId")

        // Assert
        #expect(result == false)
    }

}
