//
//  PendingRouteStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

enum PendingRouteStoreTest {

    @MainActor
    struct StoreCase {}

    @MainActor
    struct TakeHouseworkDetailItemCase {}

    @MainActor
    struct TakeHouseworkCompleteItemCase {}

    @MainActor
    struct TakeContributionAnalyticsCase {}

}

// MARK: - store / clear

extension PendingRouteStoreTest.StoreCase {

    @Test("通知から開く画面を保持する")
    func store() {
        // Arrange

        let sut = PendingRouteStore()

        // Act

        sut.store(.houseworkDetail(houseworkId: "houseworkId"))

        // Assert

        #expect(sut.pendingRoute == .houseworkDetail(houseworkId: "houseworkId"))
    }

    @Test("保持している画面を破棄する")
    func clear() {
        // Arrange

        let sut = PendingRouteStore(pendingRoute: .houseworkDetail(houseworkId: "houseworkId"))

        // Act

        sut.clear()

        // Assert

        #expect(sut.pendingRoute == nil)
    }

}

// MARK: - takeHouseworkDetailItem

extension PendingRouteStoreTest.TakeHouseworkDetailItemCase {

    @Test("開く家事が見つかったら、その家事を返して保持している画面を破棄する")
    func takeHouseworkDetailItem_found_returnsItemAndClears() {
        // Arrange

        let inputTargetItem = HouseworkItem.makeForTest(id: "target", indexedDate: .distantPast)
        let inputItems = StoredAllHouseworkList(value: [
            .makeForTest(items: [.makeForTest(id: "other", indexedDate: .distantFuture)]),
            .makeForTest(items: [inputTargetItem]),
        ])
        let sut = PendingRouteStore(pendingRoute: .houseworkDetail(houseworkId: "target"))

        // Act

        let actual = sut.takeHouseworkDetailItem(in: inputItems, loadState: .loaded)

        // Assert

        #expect(actual == inputTargetItem)
        #expect(sut.pendingRoute == nil)
    }

    @Test("家事の読み込み中に見つからない場合は、次の読み込みを待つため保持したままにする")
    func takeHouseworkDetailItem_notFoundWhileLoading_keepsRoute() {
        // Arrange

        let sut = PendingRouteStore(pendingRoute: .houseworkDetail(houseworkId: "target"))

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
        let sut = PendingRouteStore(pendingRoute: .houseworkDetail(houseworkId: "target"))

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
        let sut = PendingRouteStore()

        // Act

        let actual = sut.takeHouseworkDetailItem(in: inputItems, loadState: .loaded)

        // Assert

        #expect(actual == nil)
    }

}

// MARK: - takeHouseworkCompleteItem

extension PendingRouteStoreTest.TakeHouseworkCompleteItemCase {

    @Test("完了シートを開く家事が見つかったら、その家事を返して保持している画面を破棄する")
    func takeHouseworkCompleteItem_found_returnsItemAndClears() {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(id: "target", title: "洗濯")
        let sut = PendingRouteStore(pendingRoute: .houseworkComplete(houseworkTitle: "洗濯"))

        // Act

        let actual = sut.takeHouseworkCompleteItem(isLoading: false) { title in
            title == "洗濯" ? inputItem : nil
        }

        // Assert

        #expect(actual == inputItem)
        #expect(sut.pendingRoute == nil)
    }

    @Test("読み込み中で家事が見つからない場合は、保持している画面を残して次の読み込みを待つ")
    func takeHouseworkCompleteItem_loading_keepsRoute() {
        // Arrange

        let sut = PendingRouteStore(pendingRoute: .houseworkComplete(houseworkTitle: "洗濯"))

        // Act

        let actual: HouseworkItem? = sut.takeHouseworkCompleteItem(isLoading: true) { _ in nil }

        // Assert

        #expect(actual == nil)
        #expect(sut.pendingRoute == .houseworkComplete(houseworkTitle: "洗濯"))
    }

    @Test("読み込み終えても家事が見つからない場合は、後からシートが開かないよう破棄する")
    func takeHouseworkCompleteItem_loadedNotFound_clears() {
        // Arrange

        let sut = PendingRouteStore(pendingRoute: .houseworkComplete(houseworkTitle: "洗濯"))

        // Act

        let actual: HouseworkItem? = sut.takeHouseworkCompleteItem(isLoading: false) { _ in nil }

        // Assert

        #expect(actual == nil)
        #expect(sut.pendingRoute == nil)
    }

    @Test("完了シート以外の画面を保持している場合は、何も返さず画面も残す")
    func takeHouseworkCompleteItem_otherRoute_returnsNil() {
        // Arrange

        let sut = PendingRouteStore(pendingRoute: .houseworkDetail(houseworkId: "target"))

        // Act

        let actual = sut.takeHouseworkCompleteItem(isLoading: false) { _ in
            HouseworkItem.makeForTest(id: "target")
        }

        // Assert

        #expect(actual == nil)
        #expect(sut.pendingRoute == .houseworkDetail(houseworkId: "target"))
    }

}

// MARK: - takeContributionAnalytics

extension PendingRouteStoreTest.TakeContributionAnalyticsCase {

    @Test("分析画面を開く場合は、trueを返して保持している画面を破棄する")
    func takeContributionAnalytics_pending_returnsTrueAndClears() {
        // Arrange

        let sut = PendingRouteStore(pendingRoute: .contributionAnalytics)

        // Act

        let actual = sut.takeContributionAnalytics()

        // Assert

        #expect(actual)
        #expect(sut.pendingRoute == nil)
    }

    @Test("分析画面以外の画面を保持している場合は、falseを返して画面を残す")
    func takeContributionAnalytics_otherRoute_returnsFalse() {
        // Arrange

        let sut = PendingRouteStore(pendingRoute: .houseworkComplete(houseworkTitle: "洗濯"))

        // Act

        let actual = sut.takeContributionAnalytics()

        // Assert

        #expect(!actual)
        #expect(sut.pendingRoute == .houseworkComplete(houseworkTitle: "洗濯"))
    }

}
