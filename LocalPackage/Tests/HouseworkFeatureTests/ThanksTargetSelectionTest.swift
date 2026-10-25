//
//  ThanksTargetSelectionTest.swift
//  LocalPackage
//

@testable import HometeDomain
@testable import HouseworkFeature
import Testing

enum ThanksTargetSelectionTest {

    struct IsSelectableCase {}
    struct HasSelectableItemsCase {}
    struct TargetsCase {}

}

private extension ThanksTargetSelectionTest {

    static let notSentItem = HouseworkBoardItem.makeForPreview(
        id: "notSent",
        state: .completed,
        executorId: "otherUserId"
    )
    static let sentItem = HouseworkBoardItem.makeForPreview(
        id: "sent",
        state: .completed,
        executorId: "otherUserId",
        thanks: ["ownUserId": .init(comment: nil, sentAt: .distantPast)]
    )

}

extension ThanksTargetSelectionTest.IsSelectableCase {

    @Test("まだありがとうを送っていない家事は選択できる")
    func isSelectable_notSent_returnsTrue() {
        // Arrange

        let item = ThanksTargetSelectionTest.notSentItem
        let selection = ThanksTargetSelection(items: [item], selectedIDs: [], ownUserId: "ownUserId")

        // Act

        let actual = selection.isSelectable(item)

        // Assert

        #expect(actual)
    }

    @Test("ありがとうを送った家事は選択できない")
    func isSelectable_sent_returnsFalse() {
        // Arrange

        let item = ThanksTargetSelectionTest.sentItem
        let selection = ThanksTargetSelection(items: [item], selectedIDs: [], ownUserId: "ownUserId")

        // Act

        let actual = selection.isSelectable(item)

        // Assert

        #expect(!actual)
    }

}

extension ThanksTargetSelectionTest.HasSelectableItemsCase {

    @Test("まだありがとうを送っていない家事が1件でもあれば、選べる家事がある")
    func hasSelectableItems_containsNotSent_returnsTrue() {
        // Arrange

        let selection = ThanksTargetSelection(
            items: [ThanksTargetSelectionTest.sentItem, ThanksTargetSelectionTest.notSentItem],
            selectedIDs: [],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.hasSelectableItems

        // Assert

        #expect(actual)
    }

    @Test("すべての家事にありがとうを送っていれば、選べる家事はない")
    func hasSelectableItems_allSent_returnsFalse() {
        // Arrange

        let selection = ThanksTargetSelection(
            items: [ThanksTargetSelectionTest.sentItem],
            selectedIDs: [],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.hasSelectableItems

        // Assert

        #expect(!actual)
    }

}

extension ThanksTargetSelectionTest.TargetsCase {

    @Test("選択中の家事のうち、まだありがとうを送っていないものだけを対象にする")
    func targets_selectedContainsSent_returnsOnlyNotSent() {
        // Arrange

        let otherNotSentItem = HouseworkBoardItem.makeForPreview(
            id: "otherNotSent",
            state: .completed,
            executorId: "otherUserId"
        )
        // 選択したあとに、ほかの端末から送ったありがとうが届いて送信済みになった家事を含む
        let selection = ThanksTargetSelection(
            items: [ThanksTargetSelectionTest.notSentItem, ThanksTargetSelectionTest.sentItem, otherNotSentItem],
            selectedIDs: ["notSent", "sent"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.targets

        // Assert

        #expect(actual == [ThanksTargetSelectionTest.notSentItem])
    }

    @Test("一覧に存在しないIDが選択に残っていても、対象には含まれない")
    func targets_staleID_isIgnored() {
        // Arrange

        let selection = ThanksTargetSelection(
            items: [ThanksTargetSelectionTest.notSentItem],
            selectedIDs: ["notSent", "removed"],
            ownUserId: "ownUserId"
        )

        // Act

        let actual = selection.targets

        // Assert

        #expect(actual == [ThanksTargetSelectionTest.notSentItem])
    }

}
