//
//  HouseworkManagerFocusTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

/// 家事ボードで選んだ日だけを購読するリスナー（`focus(on:calendar:)`）のテスト
@MainActor
struct HouseworkManagerFocusTest {

    private let inputCohabitantId = "cohabitantId"
    private static let now = Date.previewDate(year: 2026, month: 8, day: 11)
    /// リアルタイムリスナーの期間（前後3日）より前の日
    private static let outOfListenerDay = Date.previewDate(year: 2026, month: 8, day: 1)
    /// リアルタイムリスナーの期間内の日
    private static let inListenerDay = Date.previewDate(year: 2026, month: 8, day: 8)

    @Test("リスナーの期間外の日を選ぶと、その日だけを購読するリスナーを張り、届いた家事をallItemsに反映する")
    func focusOutOfListenerPeriod() async {
        // Arrange

        let focusedItem = HouseworkItem.makeForTest(id: 1, indexedDate: Self.outOfListenerDay, expiredAt: Self.now)
        let (focusStream, focusContinuation) = AsyncThrowingStream<[HouseworkItem], Error>.makeStream()
        let recorder = ListenerRequestRecorder()
        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, cohabitantId, anchorDate, offset in
                    await recorder.record(.init(cohabitantId: cohabitantId, anchorDate: anchorDate, offset: offset))
                    return offset == .zero ? focusStream : .makeStream().stream
                },
                fetchItemsHandler: { _, _, _ in [] }
            )
        )
        await setupObserver(manager)
        let observerStream = await manager.createObserver("testKey")
        // 初回フェッチの通知を消費
        for await _ in observerStream {
            break
        }

        // Act

        await manager.focus(on: Self.outOfListenerDay, calendar: .japanese)
        focusContinuation.yield([focusedItem])

        // Assert

        for await _ in observerStream {
            break
        }
        focusContinuation.finish()

        let requests = await recorder.requests
        let expectedRequests: [ListenerRequest] = [
            .init(cohabitantId: inputCohabitantId, anchorDate: Self.now, offset: 3),
            .init(cohabitantId: inputCohabitantId, anchorDate: Self.outOfListenerDay, offset: .zero),
        ]
        #expect(requests == expectedRequests)
        let allItems = await manager.allItems
        #expect(allItems == [focusedItem])
    }

    @Test("リスナーの期間内の日を選んでも、その日だけのリスナーは張らない")
    func focusInListenerPeriod() async {
        // Arrange

        let recorder = ListenerRequestRecorder()
        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, cohabitantId, anchorDate, offset in
                    await recorder.record(.init(cohabitantId: cohabitantId, anchorDate: anchorDate, offset: offset))
                    return .makeStream().stream
                },
                fetchItemsHandler: { _, _, _ in [] }
            )
        )
        await setupObserver(manager)

        // Act

        await manager.focus(on: Self.inListenerDay, calendar: .japanese)

        // Assert

        let requests = await recorder.requests
        let expectedRequests: [ListenerRequest] = [
            .init(cohabitantId: inputCohabitantId, anchorDate: Self.now, offset: 3),
        ]
        #expect(requests == expectedRequests)
    }

    @Test("期間外の日からリスナーの期間内の日へ選び直すと、その日だけのリスナーを外す")
    func focusBackToListenerPeriodRemovesListener() async {
        // Arrange

        let recorder = RemovedFocusListenerRecorder()
        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                removeListenerHandler: { id in await recorder.record(id) },
                fetchItemsHandler: { _, _, _ in [] }
            )
        )
        await setupObserver(manager)
        await manager.focus(on: Self.outOfListenerDay, calendar: .japanese)

        // Act

        await manager.focus(on: Self.inListenerDay, calendar: .japanese)

        // Assert

        let removedIds = await recorder.ids
        #expect(removedIds == ["focusedDayHouseworkObserveKey-3"])
    }

    @Test("購読を準備する前に期間外の日を選んでいた場合、準備のあとにその日だけのリスナーを張る")
    func focusBeforeSetupObserver() async {
        // Arrange

        let recorder = ListenerRequestRecorder()
        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, cohabitantId, anchorDate, offset in
                    await recorder.record(.init(cohabitantId: cohabitantId, anchorDate: anchorDate, offset: offset))
                    return .makeStream().stream
                },
                fetchItemsHandler: { _, _, _ in [] }
            )
        )
        await manager.focus(on: Self.outOfListenerDay, calendar: .japanese)

        // Act

        await setupObserver(manager)

        // Assert

        let requests = await recorder.requests
        let expectedRequests: [ListenerRequest] = [
            .init(cohabitantId: inputCohabitantId, anchorDate: Self.now, offset: 3),
            .init(cohabitantId: inputCohabitantId, anchorDate: Self.outOfListenerDay, offset: .zero),
        ]
        #expect(requests == expectedRequests)
    }

    @Test("サインアウトすると、その日だけのリスナーを外す")
    func clearOnSignedOutRemovesFocusListener() async {
        // Arrange

        let recorder = RemovedFocusListenerRecorder()
        let manager = HouseworkManager(
            houseworkClient: .init(
                snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                removeListenerHandler: { id in await recorder.record(id) },
                fetchItemsHandler: { _, _, _ in [] }
            )
        )
        await setupObserver(manager)
        await manager.focus(on: Self.outOfListenerDay, calendar: .japanese)

        // Act

        await manager.clearOnSignedOut()

        // Assert

        let removedIds = await recorder.ids
        #expect(removedIds == ["focusedDayHouseworkObserveKey-3"])
    }

}

private extension HouseworkManagerFocusTest {

    func setupObserver(_ manager: HouseworkManager) async {
        await manager.setupObserver(
            currentTime: Self.now,
            cohabitantId: inputCohabitantId,
            calendar: .japanese,
            storagePolicy: .premium
        )
    }

}

/// リスナーを張るときに渡された条件
private struct ListenerRequest: Equatable {

    let cohabitantId: String
    let anchorDate: Date
    let offset: Int

}

/// 張られたリスナーの条件を記録する
private actor ListenerRequestRecorder {

    private(set) var requests: [ListenerRequest] = []

    func record(_ request: ListenerRequest) {
        requests.append(request)
    }

}

/// 外された、選んだ日だけを購読するリスナーのIDを記録する
private actor RemovedFocusListenerRecorder {

    private(set) var ids: [String] = []

    func record(_ id: String) {
        guard id.hasPrefix("focusedDayHouseworkObserveKey") else { return }
        ids.append(id)
    }

}
