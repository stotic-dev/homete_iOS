//
//  HouseworkManagerTest.swift
//  hometeTests
//
//  Created by Taichi Sato on 2026/04/11.
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkManagerTest {

    private let inputCohabitantId = "cohabitantId"

    @Test("setupObserverを呼び出すとプレミアムでは直近1年分をフェッチしリスナーを起動してallItemsに反映する")
    func setupObserver() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let calendar = Calendar.japanese
        let expectedFrom = Date.previewDate(year: 2025, month: 8, day: 11)
        let fetchedItem = HouseworkItem.makeForTest(id: 1, indexedDate: now, expiredAt: now)
        let (stream, _) = AsyncThrowingStream<[HouseworkItem], Error>.makeStream()

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { id, cohabitantId, anchorDate, offset in
                    #expect(id == "houseworkObserveKey")
                    #expect(cohabitantId == inputCohabitantId)
                    #expect(anchorDate == now)
                    #expect(offset == 3)
                    return stream
                },
                fetchItemsHandler: { cohabitantId, from, to in
                    #expect(cohabitantId == inputCohabitantId)
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
            storagePolicy: .premium
        )

        // Assert

        var receivedItems: [HouseworkItem] = []
        for await result in observerStream {
            if case let .success(items) = result {
                receivedItems = items
            }
            break
        }

        let allItems = await manager.allItems
        #expect(allItems.count == 1)
        #expect(allItems.contains(where: { $0.id == fetchedItem.id }))
        #expect(receivedItems.contains(where: { $0.id == fetchedItem.id }))
    }

    @Test("リアルタイムリスナーの更新がallItemsにupsertマージされオブザーバーに通知される")
    func streamUpdateIsUpserted() async {
        // Arrange

        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let existingItem = HouseworkItem.makeForTest(id: 1, indexedDate: now, expiredAt: now)
        let (stream, streamContinuation) = AsyncThrowingStream<[HouseworkItem], Error>.makeStream()

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
            storagePolicy: .premium
        )

        // フェッチ結果の通知を消費
        for await _ in observerStream {
            break
        }

        // Act

        let updatedItem = existingItem.updateProperties(title: "updated title")
        let newItem = HouseworkItem.makeForTest(id: 2, indexedDate: now, expiredAt: now)
        streamContinuation.yield([updatedItem, newItem])

        var receivedItems: [HouseworkItem] = []
        for await result in observerStream {
            if case let .success(items) = result {
                receivedItems = items
            }
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

    @Test("無料プランのsetupObserverは直近3ヶ月分のみをフェッチする")
    func setupObserverWithFreePlan() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let calendar = Calendar.japanese
        let expectedFrom = Date.previewDate(year: 2026, month: 5, day: 11)

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                fetchItemsHandler: { _, from, _ in
                    #expect(from == expectedFrom)
                    return []
                }
            )
        )

        // Act

        await manager.setupObserver(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar,
            storagePolicy: .free
        )

        // Assert

        let fetchedRange = await manager.fetchedRange
        #expect(fetchedRange == expectedFrom ... now)
    }

    @Test("fetchIfNeededは取得済み範囲より過去を要求されると不足分をフェッチしてマージする")
    func fetchIfNeededFetchesMissingPeriod() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let calendar = Calendar.japanese
        let initialFrom = Date.previewDate(year: 2025, month: 8, day: 11)
        let targetDate = Date.previewDate(year: 2025, month: 1, day: 1)
        // 取得済み範囲と重複しないよう、その前日までが取得されること
        let expectedTo = Date.previewDate(year: 2025, month: 8, day: 10)
        let initialItem = HouseworkItem.makeForTest(id: 1, indexedDate: now, expiredAt: now)
        let additionalItem = HouseworkItem.makeForTest(id: 2, indexedDate: targetDate, expiredAt: targetDate)

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                fetchItemsHandler: { _, from, to in
                    guard from != initialFrom else { return [initialItem] }

                    #expect(from == targetDate)
                    #expect(to == expectedTo)
                    return [additionalItem]
                }
            )
        )

        await manager.setupObserver(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar,
            storagePolicy: .premium
        )

        // Act

        await manager.fetchIfNeeded(
            until: targetDate,
            cohabitantId: inputCohabitantId,
            calendar: calendar
        )

        // Assert

        let allItems = await manager.allItems
        let fetchedRange = await manager.fetchedRange
        #expect(allItems.count == 2)
        #expect(allItems.contains(where: { $0.id == additionalItem.id }))
        #expect(fetchedRange == targetDate ... now)
    }

    @Test("リアルタイムリスナーがエラーで終了すると、オブザーバーに失敗が通知される")
    func snapshotListenerFailureNotifiesObservers() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let calendar = Calendar.japanese
        let (stream, streamContinuation) = AsyncThrowingStream<[HouseworkItem], Error>.makeStream()

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in stream },
                fetchItemsHandler: { _, _, _ in [] }
            )
        )

        let observerStream = await manager.createObserver("testKey")

        await manager.setupObserver(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar,
            storagePolicy: .premium
        )

        // フェッチ結果の通知を消費
        for await _ in observerStream {
            break
        }

        // Act

        streamContinuation.finish(throwing: DomainError.noNetwork)

        // Assert

        var receivedResult: Result<[HouseworkItem], DomainError>?
        for await result in observerStream {
            receivedResult = result
            break
        }
        #expect(receivedResult == .failure(.noNetwork))
    }

    @Test("初回フェッチに失敗すると、オブザーバーに失敗が通知される")
    func initialFetchFailureNotifiesObservers() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let calendar = Calendar.japanese

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                fetchItemsHandler: { _, _, _ in throw DomainError.noNetwork }
            )
        )

        let observerStream = await manager.createObserver("testKey")

        // Act

        await manager.setupObserver(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar,
            storagePolicy: .premium
        )

        // Assert

        var receivedResult: Result<[HouseworkItem], DomainError>?
        for await result in observerStream {
            receivedResult = result
            break
        }
        #expect(receivedResult == .failure(.noNetwork))
    }

    @Test("失敗を通知したあとにsetupObserverをやり直すと、同じオブザーバーに成功が通知される")
    func setupObserverAfterFailureNotifiesSuccess() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let calendar = Calendar.japanese
        let fetchedItem = HouseworkItem.makeForTest(id: 1, indexedDate: now, expiredAt: now)
        let (stream, streamContinuation) = AsyncThrowingStream<[HouseworkItem], Error>.makeStream()
        streamContinuation.finish(throwing: DomainError.noNetwork)

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in stream },
                fetchItemsHandler: { _, _, _ in [fetchedItem] }
            )
        )

        let observerStream = await manager.createObserver("testKey")

        await manager.setupObserver(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar,
            storagePolicy: .premium
        )
        // 初回フェッチの成功通知とリスナーの失敗通知を消費
        var consumedCount = 0
        for await _ in observerStream {
            consumedCount += 1
            if consumedCount == 2 { break }
        }

        // Act

        await manager.setupObserver(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar,
            storagePolicy: .premium
        )

        // Assert

        var receivedResult: Result<[HouseworkItem], DomainError>?
        for await result in observerStream {
            receivedResult = result
            break
        }
        #expect(receivedResult == .success([fetchedItem]))
    }

    @Test("fetchIfNeededは取得済み範囲内の日付を要求されても再フェッチしない")
    func fetchIfNeededSkipsFetchedPeriod() async {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let calendar = Calendar.japanese
        let initialFrom = Date.previewDate(year: 2025, month: 8, day: 11)
        let targetDate = Date.previewDate(year: 2026, month: 1, day: 1)

        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                fetchItemsHandler: { _, from, _ in
                    // 初回フェッチ以外は呼ばれてはいけない
                    if from != initialFrom {
                        Issue.record()
                    }
                    return []
                }
            )
        )

        await manager.setupObserver(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar,
            storagePolicy: .premium
        )

        // Act

        await manager.fetchIfNeeded(
            until: targetDate,
            cohabitantId: inputCohabitantId,
            calendar: calendar
        )

        // Assert

        let fetchedRange = await manager.fetchedRange
        #expect(fetchedRange == initialFrom ... now)
    }

}
