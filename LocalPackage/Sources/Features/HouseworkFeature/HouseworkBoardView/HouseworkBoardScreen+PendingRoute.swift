//
//  HouseworkBoardScreen+PendingRoute.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// 通知のタップやApp Intentから、家事の詳細画面・完了シートを開く
extension HouseworkBoardScreen {

    /// 開く画面を、家事やテンプレートが届くたびに探し直す
    /// - Note: 起動直後は家事がまだ読み込まれていないため、届くまで待つ。完了シートを開く家事は
    ///         テンプレートから出している家事のこともあるため、テンプレートの読み込みも待つ
    func openingPendingRoute(_ content: some View, store: HouseworkListStore) -> some View {
        content
            .onChange(of: pendingRouteStore.pendingRoute, initial: true) {
                openPendingRoute(store: store)
            }
            .onChange(of: store.loadState) {
                openPendingRoute(store: store)
            }
            .onChange(of: houseworkTemplateListStore?.loadState) {
                openPendingRoute(store: store)
            }
    }

    func openPendingRoute(store: HouseworkListStore) {
        openPendingHouseworkDetail(store: store)
        openPendingHouseworkComplete(store: store)
    }

    /// App Intentから完了シートを開く家事が見つかったら、今日の未完了の一覧に切り替えてシートを出す
    /// - Note: 今日の未完了の家事に同じ名前が無ければ（すでに完了していた場合を含む）、家事ボードを開くだけにする。
    ///         同じ名前の家事が複数あるときは、ダッシュボードの未完了の家事と同じ並びの先頭を開く
    func openPendingHouseworkComplete(store: HouseworkListStore) {
        let isLoading = store.loadState == .loading || houseworkTemplateListStore?.loadState == .loading
        guard let item = pendingRouteStore.takeHouseworkCompleteItem(isLoading: isLoading, find: { title in
            TodayHouseworkSummary.make(
                storedAllItems: store.items,
                template: templateContext.templateOfDay(by: now, calendar: calendar),
                now: now,
                calendar: calendar,
                storagePolicy: storagePolicy
            )
            .incompleteItems
            .first { $0.title == title }
        }) else { return }

        isSelecting = false
        dateList.selectDate(now, calendar: calendar)
        selectedHouseworkState = .incomplete
        navigationPath.path = []
        completingItem = item
    }

    /// 通知から開く家事が見つかったら、その家事の詳細画面を開く
    /// - Note: 別の画面を開いていても、通知の家事の詳細だけが積まれた状態にする。
    ///         詳細から戻ったときにその家事が見えるよう、ボードもその家事の日付と状態に切り替える。
    ///         シートやフルスクリーンカバーは閉じず、その裏に詳細画面を積む。購入中のペイウォールや入力中の
    ///         シートを通知で勝手に閉じないためで、ダッシュボード側のシートなどはそもそもここから閉じられない
    func openPendingHouseworkDetail(store: HouseworkListStore) {
        guard let item = pendingRouteStore.takeHouseworkDetailItem(
            in: store.items,
            loadState: store.loadState
        ) else { return }

        isSelecting = false
        dateList.selectDate(item.indexedDate.value, calendar: calendar)
        if HouseworkState.pageableCases.contains(item.state) {
            selectedHouseworkState = item.state
        }
        navigationPath.path = [.houseworkDetail(.init(originalItem: item, isRegistered: true))]
    }

}
