//
//  HouseworkManagerReflectWrittenTest.swift
//  hometeTests
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkManagerReflectWrittenTest {

    private let calendar = Calendar.japanese

    @Test("reflectWrittenはリスナーの期間より前の家事を手元へ反映する")
    func reflectWrittenUpsertsItemOutsideListenerPeriod() async {
        // Arrange

        let now = Date.now
        let pastDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -30, to: now) ?? now)
        let currentItem = HouseworkItem.makeForTest(id: 1, indexedDate: pastDate, state: .incomplete)
        let writtenItem = HouseworkItem.makeForTest(id: 1, indexedDate: pastDate, state: .completed)
        let manager = HouseworkManager(
            houseworkClient: .previewValue,
            allItems: [currentItem],
            fetchedRange: pastDate ... now
        )

        // Act

        await manager.reflectWritten([writtenItem], calendar: calendar)

        // Assert

        let allItems = await manager.allItems
        #expect(allItems == [writtenItem])
    }

    @Test("reflectWrittenはリスナーで届く期間の家事を反映しない")
    func reflectWrittenSkipsItemInsideListenerPeriod() async {
        // Arrange

        let now = Date.now
        let today = calendar.startOfDay(for: now)
        let currentItem = HouseworkItem.makeForTest(id: 1, indexedDate: today, state: .incomplete)
        let writtenItem = HouseworkItem.makeForTest(id: 1, indexedDate: today, state: .completed)
        let manager = HouseworkManager(
            houseworkClient: .previewValue,
            allItems: [currentItem],
            fetchedRange: today ... now
        )

        // Act

        await manager.reflectWritten([writtenItem], calendar: calendar)

        // Assert

        let allItems = await manager.allItems
        #expect(allItems == [currentItem])
    }

    @Test("reflectWrittenは初回フェッチを終えていなければ反映しない")
    func reflectWrittenSkipsBeforeInitialFetch() async {
        // Arrange

        let now = Date.now
        let pastDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -30, to: now) ?? now)
        let writtenItem = HouseworkItem.makeForTest(id: 1, indexedDate: pastDate, state: .completed)
        let manager = HouseworkManager(houseworkClient: .previewValue)

        // Act

        await manager.reflectWritten([writtenItem], calendar: calendar)

        // Assert

        let allItems = await manager.allItems
        #expect(allItems == [])
    }

}
