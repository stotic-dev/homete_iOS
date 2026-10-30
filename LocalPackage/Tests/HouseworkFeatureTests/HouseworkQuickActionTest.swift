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
    struct MenuActionsCase {}
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
        "状態のみからクイックアクションを判定する",
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

extension HouseworkQuickActionTest.MenuActionsCase {

    /// 家事の日付（2026/1/10）。今日・昨日の判定は日本時間で行う
    static let itemDate = Date.previewDate(year: 2026, month: 1, day: 10)

    @Test("今日の未完了の家事は、やらないの前に明日にまわすを出す")
    func menuActions_incompleteToday_insertsPostponeToTomorrowBeforeRemove() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            indexedDate: .init(value: Self.itemDate),
            state: .incomplete
        )

        // Act
        let actual = HouseworkQuickAction.menuActions(
            for: item,
            ownUserId: "ownUserId",
            canAddHelper: false,
            now: .previewDate(year: 2026, month: 1, day: 10, hour: 23, minute: 59),
            calendar: .japanese
        )

        // Assert
        #expect(actual == [.complete, .postponeToTomorrow, .remove])
    }

    @Test("昨日の未完了の家事は、やらないの前に今日にまわすを出す")
    func menuActions_incompleteYesterday_insertsPostponeToTodayBeforeRemove() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            indexedDate: .init(value: Self.itemDate),
            state: .incomplete
        )

        // Act
        let actual = HouseworkQuickAction.menuActions(
            for: item,
            ownUserId: "ownUserId",
            canAddHelper: false,
            now: .previewDate(year: 2026, month: 1, day: 11),
            calendar: .japanese
        )

        // Assert
        #expect(actual == [.complete, .postponeToToday, .remove])
    }

    @Test(
        "一昨日より前・明日以降の未完了の家事には、まわす操作を出さない",
        arguments: [
            Date.previewDate(year: 2026, month: 1, day: 12),
            .previewDate(year: 2026, month: 1, day: 9),
        ]
    )
    func menuActions_incompleteOtherDay_returnsActionsWithoutPostpone(now: Date) {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            indexedDate: .init(value: Self.itemDate),
            state: .incomplete
        )

        // Act
        let actual = HouseworkQuickAction.menuActions(
            for: item,
            ownUserId: "ownUserId",
            canAddHelper: false,
            now: now,
            calendar: .japanese
        )

        // Assert
        #expect(actual == [.complete, .remove])
    }

    @Test("完了した今日の家事には、まわす操作を出さない")
    func menuActions_completedToday_returnsActionsWithoutPostpone() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            indexedDate: .init(value: Self.itemDate),
            state: .completed,
            executorId: "otherUserId"
        )

        // Act
        let actual = HouseworkQuickAction.menuActions(
            for: item,
            ownUserId: "ownUserId",
            canAddHelper: false,
            now: Self.itemDate,
            calendar: .japanese
        )

        // Assert
        #expect(actual == [.sendThanks, .redo, .returnToIncomplete])
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
            (.postponeToTomorrow, false),
            (.postponeToToday, false),
        ]
    )
    func isAvailableInBulk(action: HouseworkQuickAction, expected: Bool) {
        // Act

        let actual = action.isAvailableInBulk

        // Assert

        #expect(actual == expected)
    }

}
