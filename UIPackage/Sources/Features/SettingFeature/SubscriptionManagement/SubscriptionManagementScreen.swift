//
//  SubscriptionManagementScreen.swift
//  LocalPackage
//

import HometeDomainUI
import HometeDomain
import HometeUI
import SettingFeatureUI
import SwiftUI

/// 契約中プランの確認・変更・復元・解約導線をまとめた画面
///
/// 設定からpushで開くほか、契約中の人がPaywallを開いたときに、プランの一覧の代わりに単独で出す（`PaywallGate`）
public struct SubscriptionManagementScreen: View {

    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.loginContext) var loginContext
    @Environment(\.routeResolver) var router
    @LoadingState var loadingState

    @State var isShowPaywall = false
    @State var isPresentedRestoreResultAlert = false
    @State var restoreResultMessage: LocalizedStringResource = ""

    /// 単独で出したときに閉じる。設定からpushしたときは`nil`
    let onClose: (() -> Void)?

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    /// 設定からpushで開く
    init() {
        onClose = nil
    }

    public var body: some View {
        if let onClose {
            NavigationStack {
                content()
                    .leadingToolbarItem {
                        NavigationBarButton(label: .close) {
                            onClose()
                        }
                    }
            }
        } else {
            content()
        }
    }

}

// MARK: - UI定義

private extension SubscriptionManagementScreen {

    func content() -> some View {
        SubscriptionManagementView(
            plan: subscriptionStore.plan,
            onTapChangePlan: { isShowPaywall = true },
            onTapRestorePurchases: { tappedRestorePurchasesButton() },
            onTapManageSubscription: { tappedManageSubscriptionButton() }
        )
        .fullScreenLoadingIndicator(loadingState)
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            // 契約中なら、契約プラン画面ではなくプランの一覧を開く（このPaywallから開いた契約プラン画面へ戻り続けないように）
            content: {
                router.resolve(.paywall(step: .subscriptionManagement, isPlanChange: subscriptionStore.isPremium))
            }
        )
        .alert(.localized("購入の復元"), isPresented: $isPresentedRestoreResultAlert) {
            Button("OK") {}
        } message: {
            Text(restoreResultMessage)
        }
        .trackScreenView(.subscriptionManagement)
    }

}

// MARK: - プレゼンテーションロジック

private extension SubscriptionManagementScreen {

    func tappedRestorePurchasesButton() {
        loadingState.task {
            await restorePurchases()
        }
    }

    func restorePurchases() async {
        do {
            let isRestored = try await subscriptionStore.restorePurchases(for: loginContext.account.id)
            restoreResultMessage = isRestored
                ? .localized("購入を復元しました")
                : .localized("復元できる購入が見つかりませんでした")
        } catch {
            restoreResultMessage = .localized("購入の復元に失敗しました。時間をおいて再度お試しください")
        }
        isPresentedRestoreResultAlert = true
    }

    func tappedManageSubscriptionButton() {
        loadingState.task {
            await subscriptionStore.showManageSubscriptions()
        }
    }

}
