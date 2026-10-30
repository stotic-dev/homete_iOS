//
//  HouseworkPostponeConfirmationTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct HouseworkPostponeConfirmationTest {

    private let item = HouseworkBoardItem.makeForPreview(id: "1", title: "お皿洗い")
    private let destination = Date.previewDate(year: 2026, month: 1, day: 11)

    @Test("まわす先の家事にまとめるときは、まとめることを確かめる")
    func init_merged_returnsMerge() {
        // Arrange
        let plan = HouseworkPostponePlan(writes: [], outcome: .merged, conflictingTitle: nil)
        let expected = HouseworkPostponeConfirmation(item: item, destination: destination, reason: .merge)

        // Act
        let actual = HouseworkPostponeConfirmation(item: item, destination: destination, plan: plan)

        // Assert
        #expect(actual == expected)
    }

    @Test("まわす先に同じ名前の家事があるときは、そのまままわすかを確かめる")
    func init_movedWithConflictingTitle_returnsSameTitle() {
        // Arrange
        let plan = HouseworkPostponePlan(writes: [], outcome: .moved, conflictingTitle: "お皿洗い")
        let expected = HouseworkPostponeConfirmation(item: item, destination: destination, reason: .sameTitle)

        // Act
        let actual = HouseworkPostponeConfirmation(item: item, destination: destination, plan: plan)

        // Assert
        #expect(actual == expected)
    }

    @Test("まとめず、同じ名前の家事も無いときは、確かめない")
    func init_movedWithoutConflict_returnsNil() {
        // Arrange
        let plan = HouseworkPostponePlan(writes: [], outcome: .moved, conflictingTitle: nil)

        // Act
        let actual = HouseworkPostponeConfirmation(item: item, destination: destination, plan: plan)

        // Assert
        #expect(actual == nil)
    }

}
