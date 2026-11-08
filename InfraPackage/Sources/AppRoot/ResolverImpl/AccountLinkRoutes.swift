//
//  AccountLinkRoutes.swift
//

import AuthFeature
import HometeDomain
import HometeUI
import PaywallFeature
import SettingFeature
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
/// 契約中の人には、プランの一覧ではなく契約プラン画面を出す（`isPlanChange`が`true`なら一覧を出す）
///
/// Paywallの表示・終了のイベントもここで送る。起点で送ると、連携の画面を閉じただけでもPaywallを見たことになるため
struct PaywallGate: View {

    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(AccountStore.self) var accountStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.dismiss) var dismiss

    let step: PaywallAnalyticsStep?
    /// 契約中のプランを変えるために開いたか
    let isPlanChange: Bool

    @State var preparation = Preparation.preparing
    /// 「もう一度試す」を押した回数。準備をやり直すきっかけにする
    @State var retryCount = 0

    var body: some View {
        if accountAuthStore.currentAuth.result?.isAnonymous == true {
            AccountLinkScreen(
                entry: .paywall,
                onClose: { dismiss() }
            )
        } else {
            preparedContent
                .task(id: PreparationTrigger(accountId: preparingAccountId, retryCount: retryCount)) {
                    await prepare(for: preparingAccountId)
                }
        }
    }

}

extension PaywallGate {

    /// 購入者をアカウントに結び付ける準備の状態
    enum Preparation {

        case preparing
        case ready(Destination)
        case failed

    }

    /// 準備ができたあとに出す画面
    /// - Note: 準備ができた時点で決める。Paywallで購入してプレミアムになっても、お礼を出す前に契約プラン画面へ切り替わらないように
    enum Destination {

        /// プランの一覧
        case paywall
        /// 契約プラン画面
        case subscriptionManagement

    }

    /// 準備をやり直すきっかけ。準備に使うアカウントが変わったときと、「もう一度試す」を押したときにやり直す
    struct PreparationTrigger: Equatable {

        let accountId: String?
        let retryCount: Int

    }

}

// MARK: UI定義

private extension PaywallGate {

    @ViewBuilder
    var preparedContent: some View {
        switch preparation {
        case .preparing:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .ready(.paywall):
            if let preparingAccountId {
                PaywallScreen(accountId: preparingAccountId, onClose: { dismiss() })
                    .onAppear { appearedPaywall() }
                    .onDisappear { disappearedPaywall() }
                    .trackScreenView(.paywall)
            }

        case .ready(.subscriptionManagement):
            // Paywallは出していないので、paywallイベントは送らない（screen_viewは契約プラン画面が送る）
            if let account = accountStore.account {
                SubscriptionManagementScreen(onClose: { dismiss() })
                    // 復元に使うアカウントを渡す。オンボーディングなど、ログイン後の画面の外から開かれることがあるため
                    .environment(\.loginContext, LoginContext(account: account))
            }

        case .failed:
            PaywallPreparationErrorView(
                onTapRetry: { retryCount += 1 },
                onTapClose: { dismiss() }
            )
        }
    }

}

// MARK: プレゼンテーションロジック

private extension PaywallGate {

    /// 準備に使うアカウントのID。認証とアカウントの読み込みがそろうまではnil
    ///
    /// Apple連携から既存のアカウントに切り替えると、認証が先に切り替わり、アカウントの読み込みと
    /// 購入者の切り替え（logOut → logIn）は後から追いかける。その間に古いアカウントで準備を終えると、
    /// 後から購入者が匿名のIDに戻ってもPaywallを出したままになるため、そろうまで待つ
    var preparingAccountId: String? {
        guard let auth = accountAuthStore.currentAuth.result,
              !auth.isAnonymous,
              let account = accountStore.account,
              account.id == auth.id else { return nil }
        return account.id
    }

    /// アカウントがそろうまでは準備中のまま待つ。そろったら購入者がそのアカウントになっているかを確かめる
    func prepare(for accountId: String?) async {
        preparation = .preparing
        guard let accountId else { return }
        let isReady = await subscriptionStore.ensureLoggedIn(accountId)
        // 確かめている間にアカウントが変わると、このTaskはキャンセルされ、新しいアカウントで準備し直す
        guard !Task.isCancelled else { return }
        guard isReady else {
            preparation = .failed
            return
        }
        preparation = .ready(subscriptionStore.isPremium && !isPlanChange ? .subscriptionManagement : .paywall)
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
