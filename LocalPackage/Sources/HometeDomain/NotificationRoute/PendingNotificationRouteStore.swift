//
//  PendingNotificationRouteStore.swift
//  LocalPackage
//

import Observation

/// タップされた通知から開く画面を保持するStore
///
/// 通知はアプリが終了していても、ログインや家事の読み込みが終わる前にタップされうるため、
/// 開く画面をここに退避し、表示できる状態になってから画面側が消化する。
@MainActor
@Observable
public final class PendingNotificationRouteStore {

    /// まだ開いていない画面
    public private(set) var pendingRoute: NotificationRoute?

    public init(pendingRoute: NotificationRoute? = nil) {
        self.pendingRoute = pendingRoute
    }

    /// 開く画面を保持する
    public func store(_ route: NotificationRoute) {
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

}
