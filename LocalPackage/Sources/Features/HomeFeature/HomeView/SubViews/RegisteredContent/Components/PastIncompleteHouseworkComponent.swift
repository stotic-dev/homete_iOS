//
//  PastIncompleteHouseworkComponent.swift
//  homete
//

import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI

/// ダッシュボードの「やり残している家事」
///
/// 取得済みの家事から昨日以前の未完了を組み立て、完了のシート・画面遷移と、プレミアムでのさらに前の家事の読み込みを受け持つ。
/// 見た目は`PastIncompleteHouseworkContent`に任せる。
struct PastIncompleteHouseworkComponent: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.adComponentResolver) var adComponentResolver
    @Environment(\.isAdsEnabled) var isAdsEnabled
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.loginContext) var loginContext
    @Environment(\.registeredContentNavigationPath) var navigationPath

    /// クイックアクションの「完了にする」で、担当者を選ぶハーフモーダルを出している家事
    @State var completingItem: HouseworkBoardItem?
    @State var olderPeriodState = OlderPeriodState.idle
    /// さらに前の家事を読み込んだ回数。末尾が表示されたままなら続けて読み込むために使う
    @State var olderPeriodLoadCount = 0
    @CommonError var commonError

    static func make() -> some View {
        PastIncompleteHouseworkComponent()
    }

    var body: some View {
        PastIncompleteHouseworkContent(
            list: .make(storedAllItems: houseworkListStore.items, now: now, calendar: calendar),
            showsAdvertisement: AdDisplayPolicy.shouldShowAds(
                isPremium: subscriptionStore.isPremium,
                isEnabled: isAdsEnabled
            ),
            isLoadingOlder: olderPeriodState == .loading,
            olderPeriodLoadCount: olderPeriodLoadCount,
            onTapItem: { navigationPath.push(.houseworkDetail($0)) },
            onTapComplete: { completingItem = $0 },
            onAppearEnd: {
                Task { await fetchOlderPeriodIfNeeded() }
            },
            rowMenu: { item in
                HouseworkQuickActionMenuContent(
                    item: item,
                    step: .dashboard,
                    // 未完了の家事だけを並べるため、ありがとうと手伝った人の追加は選ばれない
                    canAddHelper: false,
                    onSelectComplete: { completingItem = item },
                    onSelectThanks: {},
                    onSelectAddHelper: {},
                    onError: { commonError = .init(error: $0) }
                )
            },
            advertisement: { _ in
                adComponentResolver.resolve(.banner(.dashboardTop))
            }
        )
        .sheet(item: $completingItem) { item in
            HouseworkCompleteSheet(item: item, step: .dashboard)
        }
        .commonError(content: $commonError)
    }

}

extension PastIncompleteHouseworkComponent {

    /// さらに前の家事の読み込みの状態
    enum OlderPeriodState: Equatable {

        case idle
        case loading
        /// 読み込んだ期間に家事が1件も無かった。それより前は読み込まない
        case reachedEnd

    }

}

private extension PastIncompleteHouseworkComponent {

    /// プレミアムでは、一覧の末尾が表示されたら取得済みの期間より前を読み込む
    ///
    /// 無料プランは閲覧できる期間をすべて起動時に取得しているため読み込まない。
    /// 読み込んだ後も末尾が表示されたままなら、続けて前の期間を読み込む（`olderPeriodLoadCount`）。
    func fetchOlderPeriodIfNeeded() async {
        guard storagePolicy == .premium,
              olderPeriodState == .idle,
              let cohabitantId = loginContext.cohabitantId else { return }

        olderPeriodState = .loading
        let fetchedCount = await houseworkListStore.fetchOlderPeriod(cohabitantId: cohabitantId)
        switch fetchedCount {
        case 0:
            olderPeriodState = .reachedEnd

        case .some:
            olderPeriodState = .idle
            olderPeriodLoadCount += 1

        case .none:
            // 失敗したときは、次に末尾が表示されたときにやり直す
            olderPeriodState = .idle
        }
    }

}
