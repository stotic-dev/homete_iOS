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
