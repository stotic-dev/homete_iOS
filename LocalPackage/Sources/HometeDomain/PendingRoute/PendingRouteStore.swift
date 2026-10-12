//
//  PendingRouteStore.swift
//  LocalPackage
//

import Observation

/// タップされた通知やApp Intentから開く画面を保持するStore
///
/// 通知のタップやApp Intentはアプリが終了していても、ログインや家事の読み込みが終わる前に届きうるため、
/// 開く画面をここに退避し、表示できる状態になってから画面側が消化する。
@MainActor
@Observable
public final class PendingRouteStore {

    /// まだ開いていない画面
    public private(set) var pendingRoute: PendingRoute?

    public init(pendingRoute: PendingRoute? = nil) {
        self.pendingRoute = pendingRoute
    }

    /// 開く画面を保持する
    public func store(_ route: PendingRoute) {
        pendingRoute = route
    }

    /// 保持している画面を破棄する
    public func clear() {
        pendingRoute = nil
    }

    /// 詳細画面を開く家事を取り出す
    ///
    /// 見つかった家事は開いたものとして、保持している画面を破棄する。
    /// 家事を読み込み終えても見つからない場合（削除された・保存期間を過ぎた・別のグループの家事など）も、
    /// 後から急に画面が開かないよう破棄する。
    /// - Parameters:
    ///   - items: 読み込み済みの家事
    ///   - loadState: 家事の購読状態。読み込み中は見つからなくても破棄せず、次の読み込みを待つ
    /// - Returns: 詳細画面を開く家事。開く家事がない、またはまだ見つからない場合は`nil`
    public func takeHouseworkDetailItem(
        in items: StoredAllHouseworkList,
        loadState: ListenerLoadState
    ) -> HouseworkItem? {
        guard case let .houseworkDetail(houseworkId) = pendingRoute else { return nil }

        let item = items.value
            .lazy
            .flatMap(\.items)
            .first { $0.id == houseworkId }
        if item != nil || loadState != .loading {
            pendingRoute = nil
        }
        return item
    }

    /// 完了シートを開く家事を取り出す
    ///
    /// 見つかった家事は開いたものとして、保持している画面を破棄する。読み込み終えても見つからない場合
    /// （未完了の家事に同じ名前が無い・すでに完了していた）も、後から急にシートが開かないよう破棄する。
    /// - Parameters:
    ///   - isLoading: 家事やテンプレートを読み込み中かどうか。読み込み中は見つからなくても破棄せず、次の読み込みを待つ
    ///   - find: 家事の名前から、完了シートを開く家事を探す
    /// - Returns: 完了シートを開く家事。開く家事がない、またはまだ見つからない場合は`nil`
    public func takeHouseworkCompleteItem<Item>(isLoading: Bool, find: (_ houseworkTitle: String) -> Item?) -> Item? {
        guard case let .houseworkComplete(houseworkTitle) = pendingRoute else { return nil }

        let item = find(houseworkTitle)
        if item != nil || !isLoading {
            pendingRoute = nil
        }
        return item
    }

    /// がんばりの分析画面を開くかどうかを取り出す
    ///
    /// 開くと判断したら、保持している画面を破棄する。
    /// - Returns: 分析画面を開く場合は`true`
    public func takeContributionAnalytics() -> Bool {
        guard pendingRoute == .contributionAnalytics else { return false }

        pendingRoute = nil
        return true
    }

}
