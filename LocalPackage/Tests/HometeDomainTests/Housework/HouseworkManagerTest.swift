//
//  HouseworkManagerTest.swift
//  hometeTests
//
//  Created by Taichi Sato on 2026/04/11.
//

import Foundation
import Testing

@testable import HometeDomain

@MainActor
struct HouseworkManagerTest {

    private let inputCohabitantId = "cohabitantId"

    @Test("setupObserverを呼び出すと直近1年分をフェッチしリスナーを起動してallItemsに反映する")
    func setupObserver() async throws {

        // Arrange

        let now = Date()
        let calendar = Calendar.japanese
        let expectedFrom = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        let fetchedItem = HouseworkItem.makeForTest(id: 1, indexedDate: now, expiredAt: now)
        let (stream, _) = AsyncStream<[HouseworkItem]>.makeStream()

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { id, cohabitantId, anchorDate, offset in
                    #expect(id == "houseworkObserveKey")
                    #expect(cohabitantId == self.inputCohabitantId)
                    #expect(anchorDate == now)
                    #expect(offset == 3)
                    return stream
                },
                fetchItemsHandler: { cohabitantId, from, to in
                    #expect(cohabitantId == self.inputCohabitantId)
                    #expect(from == expectedFrom)
                    #expect(to == now)
                    return [fetchedItem]
                }
            )
        )

        let observerStream = await manager.createObserver("testKey")

        // Act

        await manager.setupObserver(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar,
            offset: 3
        )

        // Assert

        var receivedItems: [HouseworkItem] = []
        for await items in observerStream {
            receivedItems = items
            break
        }

        let allItems = await manager.allItems
        #expect(allItems.count == 1)
        #expect(allItems.contains(where: { $0.id == fetchedItem.id }))
        #expect(receivedItems.contains(where: { $0.id == fetchedItem.id }))
    }

    @Test("リアルタイムリスナーの更新がallItemsにupsertマージされオブザーバーに通知される")
    func streamUpdateIsUpserted() async throws {

        // Arrange

        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let existingItem = HouseworkItem.makeForTest(id: 1, indexedDate: now, expiredAt: now)
        let (stream, streamContinuation) = AsyncStream<[HouseworkItem]>.makeStream()

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in stream },
                fetchItemsHandler: { _, _, _ in [existingItem] }
            )
        )

        let observerStream = await manager.createObserver("testKey")

        await manager.setupObserver(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar,
            offset: 3
        )

        // フェッチ結果の通知を消費
        for await _ in observerStream { break }

        // Act

        let updatedItem = existingItem.updateProperties(title: "updated title")
        let newItem = HouseworkItem.makeForTest(id: 2, indexedDate: now, expiredAt: now)
        streamContinuation.yield([updatedItem, newItem])

        var receivedItems: [HouseworkItem] = []
        for await items in observerStream {
            receivedItems = items
            break
        }
        streamContinuation.finish()

        // Assert

        let allItems = await manager.allItems
        #expect(allItems.count == 2)
        #expect(allItems.contains(where: { $0.id == existingItem.id && $0.title == "updated title" }))
        #expect(allItems.contains(where: { $0.id == newItem.id }))
        #expect(receivedItems.count == 2)
    }
}
