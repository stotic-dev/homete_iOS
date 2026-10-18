//
//  AccountLinkRoutes.swift
//

import AuthFeature
import HometeDomain
import HometeInfrastructure
import HometeUI
import SwiftUI

/// Apple連携の画面をシートとして出す
/// - Note: 連携しても、閉じても、シートを閉じる
struct AccountLinkSheet: View {

    @Environment(\.dismiss) var dismiss

    let entry: AccountLinkEntry

    var body: some View {
        AccountLinkScreen(
            entry: entry,
            onClose: { dismiss() },
            onCompleted: { dismiss() }
        )
    }

}

/// Paywallを出す前に、匿名のアカウントならAppleアカウントとの連携を求める
///
/// 匿名のまま購入すると、機種変更・アンインストールで購入したプランごと失われる。
/// Paywallの起点は全て`AppRoute.paywall`を通るため、起点ごとではなくここでまとめて連携を求める。
/// 連携すると匿名でなくなり、そのままPaywallに切り替わる。閉じたらPaywallを出さずに閉じる
///
/// Paywallの表示・終了のイベントもここで送る。起点で送ると、連携の画面を閉じただけでもPaywallを見たことになるため
struct PaywallGate: View {

    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.dismiss) var dismiss

    let step: PaywallAnalyticsStep?

    var body: some View {
        if accountAuthStore.currentAuth.result?.isAnonymous == true {
            AccountLinkScreen(
                entry: .paywall,
                onClose: { dismiss() }
            )
        } else {
            // PaywallScreenはHometeInfrastructureにあり、HometeUIに依存しない。
            // 計測のためだけに依存を増やさず、画面を組み立てるここでModifierを付ける
            PaywallScreen()
                .onAppear { appearedPaywall() }
                .onDisappear { disappearedPaywall() }
                .trackScreenView(.paywall)
        }
    }

}

// MARK: プレゼンテーションロジック

private extension PaywallGate {

    func appearedPaywall() {
        guard let step else { return }
        analyticsClient.log(.paywall(.shown(step: step)))
    }

    func disappearedPaywall() {
        guard let step else { return }
        analyticsClient.log(.paywall(.closed(step: step, isPremium: subscriptionStore.isPremium)))
    }

}
