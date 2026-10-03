//
//  HouseworkDetailActionTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

enum HouseworkDetailActionTest {

    struct ActionsCase {}
    struct IsPrimaryCase {}

}

// MARK: - ActionsCase

extension HouseworkDetailActionTest.ActionsCase {

    @Test("未完了の家事では、完了にすると、やらないを出す")
    func actions_incomplete_returnsCompleteAndRemove() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .incomplete)

        // Act
        let actual = HouseworkDetailAction.actions(for: item, ownUserId: "own", canAddHelper: true)

        // Assert
        #expect(actual == [.complete, .remove])
    }

    @Test("やらないにした家事では、アクションを出さない")
    func actions_notTodo_returnsEmpty() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .notTodo)

        // Act
        let actual = HouseworkDetailAction.actions(for: item, ownUserId: "own", canAddHelper: true)

        // Assert
        #expect(actual.isEmpty)
    }

    @Test("他の人が終えた家事では、ありがとうを伝えるを先頭に出す")
    func actions_completedByOtherUser_startsWithSendThanks() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .completed, executorId: "other")

        // Act
        let actual = HouseworkDetailAction.actions(for: item, ownUserId: "own", canAddHelper: true)

        // Assert
        #expect(actual == [.sendThanks, .addHelper, .redo, .returnToIncomplete, .remove])
    }

    @Test("自分が終えた家事では、ありがとうに関するアクションを出さない")
    func actions_completedByOwnUser_hasNoThanksAction() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .completed, executorId: "own")

        // Act
        let actual = HouseworkDetailAction.actions(for: item, ownUserId: "own", canAddHelper: true)

        // Assert
        #expect(actual == [.addHelper, .redo, .returnToIncomplete, .remove])
    }

    @Test("コメントなしでありがとうを送った家事では、メッセージを添えるを出す")
    func actions_sentThanksWithoutComment_returnsAddThanksMessage() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "other",
            thanks: ["own": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 1, day: 1))]
        )

        // Act
        let actual = HouseworkDetailAction.actions(for: item, ownUserId: "own", canAddHelper: true)

        // Assert
        #expect(actual == [.addThanksMessage, .addHelper, .redo, .returnToIncomplete, .remove])
    }

    @Test("メッセージを添えて送った家事では、送ったメッセージを編集を出す")
    func actions_sentThanksWithComment_returnsEditThanksMessage() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "other",
            thanks: ["own": .init(comment: "ありがとう", sentAt: .previewDate(year: 2026, month: 1, day: 1))]
        )

        // Act
        let actual = HouseworkDetailAction.actions(for: item, ownUserId: "own", canAddHelper: true)

        // Assert
        #expect(actual == [.editThanksMessage, .addHelper, .redo, .returnToIncomplete, .remove])
    }

    @Test("手伝った人を足せない家事では、手伝った人を追加を出さない")
    func actions_cannotAddHelper_hasNoAddHelper() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .completed, executorId: "other")

        // Act
        let actual = HouseworkDetailAction.actions(for: item, ownUserId: "own", canAddHelper: false)

        // Assert
        #expect(actual == [.sendThanks, .redo, .returnToIncomplete, .remove])
    }

}

// MARK: - IsPrimaryCase

extension HouseworkDetailActionTest.IsPrimaryCase {

    @Test(
        "よく使うアクションは、ナビゲーションバーに単独のボタンとして出す",
        arguments: [
            HouseworkDetailAction.complete,
            .sendThanks,
            .addThanksMessage,
            .editThanksMessage,
        ]
    )
    func isPrimary_frequentAction_returnsTrue(action: HouseworkDetailAction) {
        // Act
        let actual = action.isPrimary

        // Assert
        #expect(actual == true)
    }

    @Test(
        "ステータスを変える・取り下げるアクションは、単独のボタンとして出さない",
        arguments: [
            HouseworkDetailAction.addHelper,
            .redo,
            .returnToIncomplete,
            .remove,
        ]
    )
    func isPrimary_stateChangingAction_returnsFalse(action: HouseworkDetailAction) {
        // Act
        let actual = action.isPrimary

        // Assert
        #expect(actual == false)
    }

}
