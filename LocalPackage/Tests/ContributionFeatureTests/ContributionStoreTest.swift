//
//  ContributionStoreTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/27.
//

import Foundation
import Testing
import HometeDomain
@testable import ContributionFeature

@MainActor
struct ContributionStoreTest {

    private let inputCohabitantId = "cohabitantId"
    private let calendar = Calendar.japanese
}

extension ContributionStoreTest {

    @Test("HouseworkManagerがフェッチしたアイテムを流すと完了済みのみcontributionに反映される")
    func startObserving_updatesContributionWithOnlyCompletedItems() async {

        // Arrange
        let now = Date()
        let jan10 = Date.previewDate(year: 2026, month: 1, day: 10)
        let items: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: jan10, point: 30, state: .completed, executorId: "alice"),
            .makeForTest(id: 2, indexedDate: jan10, point: 20, state: .incomplete, executorId: "alice")
        ]
        let (stream, _) = AsyncStream<[HouseworkItem]>.makeStream()

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in stream },
                fetchItemsHandler: { _, _, _ in items }
            )
        )

        let store = ContributionStore(houseworkManager: manager, calendar: calendar)

        let waiterForContribution = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking({ store.contiribution }) {
                    continuation.resume(returning: ())
                }
            }
        }

        // Act
        await manager.setupObserver(currentTime: now, cohabitantId: inputCohabitantId, calendar: calendar)
        await waiterForContribution.value

        // Assert: 完了済み家事のみ集計される
        let expectedContribution = HouseworkContribution(
            list: ["": [.init(indexedDay: jan10, point: .init(value: 30))]]
        )
        #expect(store.contiribution == expectedContribution)
    }
}
