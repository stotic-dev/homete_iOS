//
//  HouseworkSelectionTest.swift
//  LocalPackage
//

@testable import HometeDomain
@testable import HouseworkFeature
import Testing

enum HouseworkSelectionTest {

    struct SelectedItemsCase {}
    struct AvailableActionsCase {}
    struct IsSelectableCase {}
    struct TargetsCase {}

}

extension HouseworkSelectionTest.SelectedItemsCase {

    @Test("選択中のIDに一致する家事だけを返す")
    func selectedItems_returnsMatchingItems() {
        // Arrange

        let items = [
            HouseworkBoardItem.makeForPreview(id: "1", state: .incomplete),
            HouseworkBoardItem.makeForPreview(id: "2", state: .incomplete),
            HouseworkBoardItem.makeForPreview(id: "3", state: .incomplete),
        ]
        let selection = HouseworkSelection(
            items: items,
            state: .incomplete,
            selectedIDs: ["1", "3"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.selectedItems

        // Assert

        #expect(actual == [items[0], items[2]])
    }

    @Test("リストに存在しないIDが選択に残っていても、選択中の家事には含まれない")
    func selectedItems_staleID_isIgnored() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .incomplete)
        let selection = HouseworkSelection(
            items: [item],
            state: .incomplete,
            selectedIDs: ["1", "removed"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.selectedItems

        // Assert

        #expect(actual == [item])
    }

}

extension HouseworkSelectionTest.AvailableActionsCase {

    @Test(
        "何も選択されていない場合は、タブのステータスから決まる既定のアクションを返す",
        arguments: [
            (HouseworkState.incomplete, [HouseworkQuickAction.complete, .remove]),
            (.completed, [.sendThanks, .returnToIncomplete]),
            (.notTodo, []),
        ]
    )
    func availableActions_emptySelection_returnsDefaultActionsForState(
        state: HouseworkState,
        expected: [HouseworkQuickAction]
    ) {
        // Arrange

        let selection = HouseworkSelection(
            items: [.makeForPreview(id: "1", state: state)],
            state: state,
            selectedIDs: [],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.availableActions

        // Assert

        #expect(actual == expected)
    }

    @Test("完了済みで自分が実施した家事だけを選んだ場合は、未完了に戻すのみが行える")
    func availableActions_completedByOwnUserOnly_returnsReturnToIncompleteOnly() {
        // Arrange

        let selection = HouseworkSelection(
            items: [
                .makeForPreview(id: "1", state: .completed, executorId: "ownUserId"),
                .makeForPreview(id: "2", state: .completed, executorId: "ownUserId"),
            ],
            state: .completed,
            selectedIDs: ["1", "2"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.availableActions

        // Assert

        #expect(actual == [.returnToIncomplete])
    }

    @Test("実施者が異なる完了済みの家事が混在する場合は、両方のアクションを列挙順で返す")
    func availableActions_mixedExecutors_returnsUnionInDeclarationOrder() {
        // Arrange

        let selection = HouseworkSelection(
            items: [
                .makeForPreview(id: "1", state: .completed, executorId: "ownUserId"),
                .makeForPreview(id: "2", state: .completed, executorId: "otherUserId"),
            ],
            state: .completed,
            selectedIDs: ["1", "2"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.availableActions

        // Assert

        #expect(actual == [.sendThanks, .returnToIncomplete])
    }

    @Test("同じアクションを持つ家事を複数選んでも、アクションは重複しない")
    func availableActions_sameActionItems_returnsUniqueActions() {
        // Arrange

        let selection = HouseworkSelection(
            items: [
                .makeForPreview(id: "1", state: .incomplete),
                .makeForPreview(id: "2", state: .incomplete),
            ],
            state: .incomplete,
            selectedIDs: ["1", "2"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.availableActions

        // Assert

        #expect(actual == [.complete, .remove])
    }

}

extension HouseworkSelectionTest.IsSelectableCase {

    @Test("まだ何も選択されていない場合は、どの家事も選択できる")
    func isSelectable_noSelection_returnsTrue() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "1", state: .completed, executorId: "ownUserId")
        let selection = HouseworkSelection(
            items: [item],
            state: .completed,
            selectedIDs: [],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.isSelectable(item)

        // Assert

        #expect(actual == true)
    }

    @Test("対応可能アクションが同じ家事は一緒に選択できる")
    func isSelectable_sameActions_returnsTrue() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "2", state: .completed, executorId: "otherUserId")
        let selection = HouseworkSelection(
            items: [
                .makeForPreview(id: "1", state: .completed, executorId: "otherUserId"),
                item,
            ],
            state: .completed,
            selectedIDs: ["1"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.isSelectable(item)

        // Assert

        #expect(actual == true)
    }

    @Test("完了済みでも実施者が異なり対応可能アクションが変わる家事は一緒に選択できない")
    func isSelectable_differentActionsInSameState_returnsFalse() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "2", state: .completed, executorId: "ownUserId")
        let selection = HouseworkSelection(
            items: [
                .makeForPreview(id: "1", state: .completed, executorId: "otherUserId"),
                item,
            ],
            state: .completed,
            selectedIDs: ["1"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.isSelectable(item)

        // Assert

        #expect(actual == false)
    }

    @Test("ステータスが異なり対応可能アクションが変わる家事は一緒に選択できない")
    func isSelectable_differentState_returnsFalse() {
        // Arrange

        let item = HouseworkBoardItem.makeForPreview(id: "2", state: .completed)
        let selection = HouseworkSelection(
            items: [
                .makeForPreview(id: "1", state: .incomplete),
                item,
            ],
            state: .incomplete,
            selectedIDs: ["1"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.isSelectable(item)

        // Assert

        #expect(actual == false)
    }

}

extension HouseworkSelectionTest.TargetsCase {

    @Test("選択中の家事がすべてそのアクションを行える場合は、選択中の全件が対象になる")
    func targets_allSelectedItemsSupportAction_returnsAllSelectedItems() {
        // Arrange

        let items = [
            HouseworkBoardItem.makeForPreview(id: "1", state: .incomplete),
            HouseworkBoardItem.makeForPreview(id: "2", state: .incomplete),
        ]
        let selection = HouseworkSelection(
            items: items,
            state: .incomplete,
            selectedIDs: ["1", "2"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.targets(for: .complete)

        // Assert

        #expect(actual == items)
    }

    @Test("そのアクションを行えない家事が選択に混ざっている場合は、対象から除外する")
    func targets_unsupportedItemInSelection_isExcluded() {
        // Arrange

        let thanksTargetItem = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId"
        )
        let selection = HouseworkSelection(
            items: [
                thanksTargetItem,
                .makeForPreview(id: "2", state: .completed, executorId: "ownUserId"),
            ],
            state: .completed,
            selectedIDs: ["1", "2"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.targets(for: .sendThanks)

        // Assert

        #expect(actual == [thanksTargetItem])
    }

}
