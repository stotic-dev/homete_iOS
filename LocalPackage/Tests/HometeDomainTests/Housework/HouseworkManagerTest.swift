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

    @Test("setupObserverを呼び出すと直近1年分の家事をワンショットフェッチする")
    func setupObserverFetchesOneYear() async throws {

        // Arrange

        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let expectedFrom = calendar.date(byAdding: .year, value: -1, to: now) ?? now

        try await confirmation { confirmation in

            let manager = HouseworkManager(
                houseworkClient: .init(
                    snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                    fetchItemsHandler: { cohabitantId, from, to in

                        // Assert

                        #expect(cohabitantId == inputCohabitantId)
                        #expect(from == expectedFrom)
                        #expect(to == now)
                        confirmation()
                        return []
                    }
                )
            )

            // Act

            await manager.setupObserver(
                currentTime: now,
                cohabitantId: inputCohabitantId,
                calendar: calendar,
                offset: 3
            )
        }
    }

    @Test("setupObserverを呼び出すとリアルタイムリスナーを起動する")
    func setupObserverStartsSnapshotListener() async throws {

        // Arrange

        let now = Date()
        let calendar = Calendar.autoupdatingCurrent

        try await confirmation { confirmation in

            let manager = HouseworkManager(
                houseworkClient: .init(
                    snapshotListenerHandler: { id, cohabitantId, anchorDate, offset in

                        // Assert

                        #expect(id == "houseworkObserveKey")
                        #expect(cohabitantId == inputCohabitantId)
                        #expect(anchorDate == now)
                        #expect(offset == 3)
                        confirmation()
                        return .makeStream().stream
                    },
                    fetchItemsHandler: { _, _, _ in [] }
                )
            )

            // Act

            await manager.setupObserver(
                currentTime: now,
                cohabitantId: inputCohabitantId,
                calendar: calendar,
                offset: 3
            )
        }
    }

    @Test("setupObserverのフェッチ結果がallItemsとオブザーバーに反映される")
    func fetchedItemsAreReflectedInAllItemsAndObserver() async throws {

        // Arrange

        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let fetchedItems: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: now, expiredAt: now),
            .makeForTest(id: 2, indexedDate: now, expiredAt: now)
        ]

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                fetchItemsHandler: { _, _, _ in fetchedItems }
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

        // Assert: オブザーバーストリームにフェッチ結果が流れてくる

        var receivedItems: [HouseworkItem] = []
        for await items in observerStream {
            receivedItems = items
            break
        }

        let allItems = await manager.allItems
        #expect(allItems.count == 2)
        #expect(receivedItems.count == 2)
        #expect(fetchedItems.allSatisfy { fetched in allItems.contains(where: { $0.id == fetched.id }) })
    }

    @Test("リアルタイムリスナーの更新がallItemsにupsertマージされオブザーバーに通知される")
    func streamUpdateIsUpsertedAndNotifiesObserver() async throws {

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

        // フェッチ結果（1件）の通知を消費
        for await _ in observerStream {
            break
        }

        // Act: 既存アイテムの更新 + 新規アイテムを yield

        let updatedExistingItem = existingItem.updateProperties(title: "updated title")
        let newItem = HouseworkItem.makeForTest(id: 2, indexedDate: now, expiredAt: now)
        streamContinuation.yield([updatedExistingItem, newItem])

        var receivedItems: [HouseworkItem] = []
        for await items in observerStream {
            receivedItems = items
            break
        }
        streamContinuation.finish()

        // Assert: upsert されて allItems が2件になり、既存アイテムが更新されている

        let allItems = await manager.allItems
        #expect(allItems.count == 2)
        #expect(allItems.contains(where: { $0.id == existingItem.id && $0.title == "updated title" }))
        #expect(allItems.contains(where: { $0.id == newItem.id }))
        #expect(receivedItems.count == 2)
    }
}
