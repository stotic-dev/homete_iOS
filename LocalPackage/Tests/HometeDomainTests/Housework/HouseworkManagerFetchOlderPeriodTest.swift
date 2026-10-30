//
//  HouseworkManagerFetchOlderPeriodTest.swift
//  hometeTests
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkManagerFetchOlderPeriodTest {

    private let inputCohabitantId = "cohabitantId"

    @Test("fetchOlderPeriodは取得済み範囲の前日から指定した月数前までをフェッチし、取得した件数を返す")
    func fetchOlderPeriodFetchesPreviousMonths() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let fetchedFrom = Date.previewDate(year: 2025, month: 8, day: 11)
        let expectedFrom = Date.previewDate(year: 2025, month: 5, day: 11)
        let expectedTo = Date.previewDate(year: 2025, month: 8, day: 10)
        let olderItems = [
            HouseworkItem.makeForTest(id: 1, indexedDate: expectedFrom, expiredAt: expectedFrom),
            HouseworkItem.makeForTest(id: 2, indexedDate: expectedTo, expiredAt: expectedTo),
        ]

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                fetchItemsHandler: { _, from, to in
                    #expect(from == expectedFrom)
                    #expect(to == expectedTo)
                    return olderItems
                }
            ),
            allItems: [],
            fetchedRange: fetchedFrom ... now
        )

        // Act

        let actual = await manager.fetchOlderPeriod(
            months: 3,
            cohabitantId: inputCohabitantId,
            calendar: .japanese
        )

        // Assert

        let fetchedRange = await manager.fetchedRange
        #expect(actual == 2)
        #expect(fetchedRange == expectedFrom ... now)
    }

    @Test("fetchOlderPeriodは初回フェッチを終えていなければフェッチせずnilを返す")
    func fetchOlderPeriodReturnsNilBeforeInitialFetch() async {
        // Arrange

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                fetchItemsHandler: { _, _, _ in
                    Issue.record("初回フェッチ前に追加フェッチしてはいけない")
                    return []
                }
            )
        )

        // Act

        let actual = await manager.fetchOlderPeriod(
            months: 3,
            cohabitantId: inputCohabitantId,
            calendar: .japanese
        )

        // Assert

        #expect(actual == nil)
    }

    @Test("fetchOlderPeriodはフェッチに失敗するとnilを返し、取得済み範囲を変えない")
    func fetchOlderPeriodReturnsNilOnFailure() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let fetchedFrom = Date.previewDate(year: 2025, month: 8, day: 11)

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                fetchItemsHandler: { _, _, _ in throw DomainError.other }
            ),
            allItems: [],
            fetchedRange: fetchedFrom ... now
        )

        // Act

        let actual = await manager.fetchOlderPeriod(
            months: 3,
            cohabitantId: inputCohabitantId,
            calendar: .japanese
        )

        // Assert

        let fetchedRange = await manager.fetchedRange
        #expect(actual == nil)
        #expect(fetchedRange == fetchedFrom ... now)
    }

}
