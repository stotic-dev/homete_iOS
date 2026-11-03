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
/// Paywallを出す前に、購入者（RevenueCatのApp User ID）がアカウントになっているかも確かめる。
/// `logIn`に失敗したままだと匿名のIDで購入され、加入がサーバーに届かないため、なっていなければログインし直し、
/// それも失敗したらPaywallを出さずにやり直しを促す
///
/// Paywallの表示・終了のイベントもここで送る。起点で送ると、連携の画面を閉じただけでもPaywallを見たことになるため
struct PaywallGate: View {

    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(AccountStore.self) var accountStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.dismiss) var dismiss

    let step: PaywallAnalyticsStep?

    @State var preparation = PaywallPreparation.preparing

    var body: some View {
        if accountAuthStore.currentAuth.result?.isAnonymous == true {
            AccountLinkScreen(
                entry: .paywall,
                onClose: { dismiss() }
            )
        } else {
            preparedContent
                .task { await prepare() }
        }
    }

}

/// 購入者をアカウントに結び付ける準備の状態
enum PaywallPreparation {

    case preparing
    case ready
    case failed

}

// MARK: UI定義

private extension PaywallGate {

    @ViewBuilder
    var preparedContent: some View {
        switch preparation {
        case .preparing:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .ready:
            // PaywallScreenはHometeInfrastructureにあり、HometeUIに依存しない。
            // 計測のためだけに依存を増やさず、画面を組み立てるここでModifierを付ける
            PaywallScreen()
                .onAppear { appearedPaywall() }
                .onDisappear { disappearedPaywall() }
                .trackScreenView(.paywall)

        case .failed:
            PaywallPreparationErrorView(
                onTapRetry: { Task { await retry() } },
                onTapClose: { dismiss() }
            )
        }
    }

}

// MARK: プレゼンテーションロジック

private extension PaywallGate {

    /// 準備済みなら何もしない。Apple連携からPaywallに切り替わったときにも、ここで準備を始める
    func prepare() async {
        guard preparation == .preparing else { return }
        guard let accountId = accountStore.account?.id else {
            preparation = .failed
            return
        }
        preparation = await subscriptionStore.ensureLoggedIn(accountId) ? .ready : .failed
    }

    func retry() async {
        preparation = .preparing
        await prepare()
    }

    func appearedPaywall() {
        guard let step else { return }
        analyticsClient.log(.paywall(.shown(step: step)))
    }

    func disappearedPaywall() {
        guard let step else { return }
        analyticsClient.log(.paywall(.closed(step: step, isPremium: subscriptionStore.isPremium)))
    }

}
