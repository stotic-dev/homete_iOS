//
//  HouseworkQuickActionTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

enum HouseworkQuickActionTest {

    struct ActionsForItemCase {}
    struct ActionsForStateCase {}

}

extension HouseworkQuickActionTest.ActionsForItemCase {

    @Test("未完了の家事は完了にするとやらないが行える")
    func actions_incomplete_returnsCompleteAndRemove() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .incomplete)

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [.complete, .remove])
    }

    @Test("完了済みで自分以外が実施した家事は、ありがとう・もう一度やった・未完了に戻すが行える")
    func actions_completedByOtherUser_returnsSendThanksRedoAndReturnToIncomplete() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId"
        )

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [.sendThanks, .redo, .returnToIncomplete])
    }

    @Test("完了済みで自分以外が実施した家事でも、すでにありがとうを送っていれば、ありがとうは行えない")
    func actions_completedByOtherUserAlreadyThanked_returnsRedoAndReturnToIncomplete() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId",
            thanks: ["ownUserId": .init(comment: nil, sentAt: .distantPast)]
        )

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [.redo, .returnToIncomplete])
    }

    @Test("完了済みで自分が実施した家事は、もう一度やったと未完了に戻すが行える")
    func actions_completedByOwnUser_returnsRedoAndReturnToIncomplete() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "ownUserId"
        )

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [.redo, .returnToIncomplete])
    }

    @Test("やらない扱いの家事はクイックアクションを行えない")
    func actions_notTodo_returnsEmpty() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .notTodo)

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [])
    }

}

extension HouseworkQuickActionTest.ActionsForStateCase {

    @Test(
        "状態のみからクイックアクションを判定する（一括操作用）",
        arguments: [
            (HouseworkState.incomplete, [HouseworkQuickAction.complete, .remove]),
            (.completed, [.sendThanks, .returnToIncomplete]),
            (.notTodo, []),
        ]
    )
    func actions_forState(state: HouseworkState, expected: [HouseworkQuickAction]) {
        // Act

        let actual = HouseworkQuickAction.actions(for: state)

        // Assert

        #expect(actual == expected)
    }

}
