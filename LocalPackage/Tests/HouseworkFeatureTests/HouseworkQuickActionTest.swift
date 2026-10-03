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
    struct IsAvailableInBulkCase {}

}

extension HouseworkQuickActionTest.ActionsForItemCase {

    @Test("未完了の家事は完了にするとやらないが行える")
    func actions_incomplete_returnsCompleteAndRemove() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .incomplete)

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId", canAddHelper: false)

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

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId", canAddHelper: false)

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

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId", canAddHelper: false)

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

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId", canAddHelper: false)

        // Assert

        #expect(actual == [.redo, .returnToIncomplete])
    }

    @Test("完了済みで手伝った人を足せる家事は、ありがとうの次に手伝った人を追加を出す")
    func actions_completedAndCanAddHelper_returnsAddHelperAfterSendThanks() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId"
        )

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId", canAddHelper: true)

        // Assert

        #expect(actual == [.sendThanks, .addHelper, .redo, .returnToIncomplete])
    }

    @Test("完了済みで自分が実施した家事でも、手伝った人を足せるなら手伝った人を追加を出す")
    func actions_completedByOwnUserAndCanAddHelper_returnsAddHelper() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "ownUserId"
        )

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId", canAddHelper: true)

        // Assert

        #expect(actual == [.addHelper, .redo, .returnToIncomplete])
    }

    @Test("未完了の家事には、手伝った人を足せる状態でも手伝った人を追加を出さない")
    func actions_incompleteAndCanAddHelper_hasNoAddHelper() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .incomplete)

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId", canAddHelper: true)

        // Assert

        #expect(actual == [.complete, .remove])
    }

    @Test("やらない扱いの家事はクイックアクションを行えない")
    func actions_notTodo_returnsEmpty() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .notTodo)

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId", canAddHelper: false)

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

extension HouseworkQuickActionTest.IsAvailableInBulkCase {

    @Test(
        "1件ずつ入力を決めるアクションは、複数選択の一括操作で行えない",
        arguments: [
            (HouseworkQuickAction.complete, true),
            (.remove, true),
            (.sendThanks, true),
            (.addHelper, false),
            (.redo, false),
            (.returnToIncomplete, true),
        ]
    )
    func isAvailableInBulk(action: HouseworkQuickAction, expected: Bool) {
        // Act

        let actual = action.isAvailableInBulk

        // Assert

        #expect(actual == expected)
    }

}
