//
//  PendingNotificationRouteStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct PendingNotificationRouteStoreTest {

    @Test("通知から開く画面を保持する")
    func store() {
        // Arrange

        let sut = PendingNotificationRouteStore()

        // Act

        sut.store(.houseworkDetail(houseworkId: "houseworkId"))

        // Assert

        #expect(sut.pendingRoute == .houseworkDetail(houseworkId: "houseworkId"))
    }

    @Test("保持している画面を破棄する")
    func clear() {
        // Arrange

        let sut = PendingNotificationRouteStore(pendingRoute: .houseworkDetail(houseworkId: "houseworkId"))

        // Act

        sut.clear()

        // Assert

        #expect(sut.pendingRoute == nil)
    }

}

// MARK: - takeHouseworkDetailItem

extension PendingNotificationRouteStoreTest {

    @Test("開く家事が見つかったら、その家事を返して保持している画面を破棄する")
    func takeHouseworkDetailItem_found_returnsItemAndClears() {
        // Arrange

        let inputTargetItem = HouseworkItem.makeForTest(id: "target", indexedDate: .distantPast)
        let inputItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [.makeForTest(id: "other", indexedDate: .distantFuture)]),
            .makeForTest(items: [inputTargetItem]),
        ])
        let sut = PendingNotificationRouteStore(pendingRoute: .houseworkDetail(houseworkId: "target"))

        // Act

        let actual = sut.takeHouseworkDetailItem(in: inputItems, loadState: .loaded)

        // Assert

        #expect(actual == inputTargetItem)
        #expect(sut.pendingRoute == nil)
    }

    @Test("家事の読み込み中に見つからない場合は、次の読み込みを待つため保持したままにする")
    func takeHouseworkDetailItem_notFoundWhileLoading_keepsRoute() {
        // Arrange

        let sut = PendingNotificationRouteStore(pendingRoute: .houseworkDetail(houseworkId: "target"))

        // Act

        let actual = sut.takeHouseworkDetailItem(in: .init(value: []), loadState: .loading)

        // Assert

        #expect(actual == nil)
        #expect(sut.pendingRoute == .houseworkDetail(houseworkId: "target"))
    }

    @Test(
        "家事を読み込み終えても見つからない場合は、後から画面が開かないよう破棄する",
        arguments: [ListenerLoadState.loaded, .failed(.other)]
    )
    func takeHouseworkDetailItem_notFoundAfterLoading_clears(loadState: ListenerLoadState) {
        // Arrange

        let inputItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [.makeForTest(id: "other")]),
        ])
        let sut = PendingNotificationRouteStore(pendingRoute: .houseworkDetail(houseworkId: "target"))

        // Act

        let actual = sut.takeHouseworkDetailItem(in: inputItems, loadState: loadState)

        // Assert

        #expect(actual == nil)
        #expect(sut.pendingRoute == nil)
    }

    @Test("開く画面を保持していない場合は、何も返さない")
    func takeHouseworkDetailItem_noPendingRoute_returnsNil() {
        // Arrange

        let inputItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [.makeForTest(id: "target")]),
        ])
        let sut = PendingNotificationRouteStore()

        // Act

        let actual = sut.takeHouseworkDetailItem(in: inputItems, loadState: .loaded)

        // Assert

        #expect(actual == nil)
    }

}
