//
//  HouseworkQuickActionTest.swift
//  LocalPackage
//

@testable import HometeDomain
@testable import HouseworkFeature
import Testing

enum HouseworkQuickActionTest {

    struct ActionsForItemCase {}
    struct ActionsForStateCase {}
    struct BulkNotificationCase {}

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

    @Test("完了済みで自分以外が実施した家事は、ありがとうと未完了に戻すが行える")
    func actions_completedByOtherUser_returnsSendThanksAndReturnToIncomplete() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId"
        )

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [.sendThanks, .returnToIncomplete])
    }

    @Test("完了済みで自分が実施した家事は、未完了に戻すしか行えない")
    func actions_completedByOwnUser_returnsReturnToIncompleteOnly() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "ownUserId"
        )

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [.returnToIncomplete])
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

extension HouseworkQuickActionTest.BulkNotificationCase {

    @Test("完了の一括通知は実施者名と件数を含むメッセージになる")
    func bulkNotification_complete_returnsExecutorNameAndCountMessage() {
        // Act

        let actual = HouseworkQuickAction.complete.bulkNotification(count: 3, senderName: "じっこうしゃ")

        // Assert

        let expected = PushNotificationContent(
            title: "じっこうしゃさんが家事を終えました",
            message: "3件の家事が完了しました"
        )
        #expect(actual == expected)
    }

    @Test("ありがとうの一括通知は送信者名と件数を含むメッセージになる")
    func bulkNotification_sendThanks_returnsSenderNameAndCountMessage() {
        // Act

        let actual = HouseworkQuickAction.sendThanks.bulkNotification(count: 2, senderName: "おくりぬし")

        // Assert

        let expected = PushNotificationContent(
            title: "おくりぬしさんからありがとうが届きました",
            message: "2件の家事にありがとうが届きました"
        )
        #expect(actual == expected)
    }

    @Test(
        "相手に通知しないアクションはnilを返す",
        arguments: [HouseworkQuickAction.remove, .returnToIncomplete]
    )
    func bulkNotification_nonNotifyingActions_returnsNil(action: HouseworkQuickAction) {
        // Act

        let actual = action.bulkNotification(count: 1, senderName: "おくりぬし")

        // Assert

        #expect(actual == nil)
    }

}
