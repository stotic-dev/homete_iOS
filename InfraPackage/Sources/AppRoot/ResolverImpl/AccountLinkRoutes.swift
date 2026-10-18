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
struct PaywallGate: View {

    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(\.dismiss) var dismiss

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
                .trackScreenView(.paywall)
        }
    }

}
