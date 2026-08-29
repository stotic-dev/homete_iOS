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

    @Test("未完了の家事は承認依頼とやらないが行える")
    func actions_incomplete_returnsRequestReviewAndRemove() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .incomplete)

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [.requestReview, .remove])
    }

    @Test("承認待ちで自分以外が実施した家事は、承認とやり直し依頼が行える")
    func actions_pendingApprovalByOtherUser_returnsApproveAndReject() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .pendingApproval,
            executorId: "otherUserId"
        )

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [.approve, .reject])
    }

    @Test("承認待ちで自分が実施した家事は、差し戻ししか行えない")
    func actions_pendingApprovalByOwnUser_returnsReturnToIncompleteOnly() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .pendingApproval,
            executorId: "ownUserId"
        )

        // Act

        let actual = HouseworkQuickAction.actions(for: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == [.returnToIncomplete])
    }

    @Test("完了済みの家事は差し戻ししか行えない")
    func actions_completed_returnsReturnToIncompleteOnly() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .completed)

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
            (HouseworkState.incomplete, [HouseworkQuickAction.requestReview, .remove]),
            (.pendingApproval, [.approve, .reject]),
            (.completed, [.returnToIncomplete]),
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

    @Test("承認依頼の一括通知は件数をまとめたメッセージになる")
    func bulkNotification_requestReview_returnsCountMessage() {
        // Act

        let actual = HouseworkQuickAction.requestReview.bulkNotification(count: 3, reviewerName: "reviewer")

        // Assert

        #expect(actual == .requestReviewBulkMessage(count: 3))
    }

    @Test("ありがとうの一括通知は承認者名と件数を含むメッセージになる")
    func bulkNotification_approve_returnsReviewerNameAndCountMessage() {
        // Act

        let actual = HouseworkQuickAction.approve.bulkNotification(count: 2, reviewerName: "reviewer")

        // Assert

        #expect(actual == .approvedBulkMessage(reviwerName: "reviewer", count: 2))
    }

    @Test("再確認依頼の一括通知は件数をまとめたメッセージになる")
    func bulkNotification_reject_returnsCountMessage() {
        // Act

        let actual = HouseworkQuickAction.reject.bulkNotification(count: 4, reviewerName: "reviewer")

        // Assert

        #expect(actual == .rejectedBulkMessage(count: 4))
    }

    @Test(
        "相手に通知しないアクションはnilを返す",
        arguments: [HouseworkQuickAction.remove, .returnToIncomplete]
    )
    func bulkNotification_nonNotifyingActions_returnsNil(action: HouseworkQuickAction) {
        // Act

        let actual = action.bulkNotification(count: 1, reviewerName: "reviewer")

        // Assert

        #expect(actual == nil)
    }

}
