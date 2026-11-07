//
//  PaywallScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// プレミアムプランのPaywall
///
/// Storeの生成とプランの取得・購入・復元を担い、見た目は `PaywallView` に状態を渡して描画する。
/// 表示直後に取得を始めるため、この画面自体はPreview（VRT）の対象にしない（常に取得中の見た目になる）。
/// - Note: 匿名ユーザーへのApple連携の要求と、購入者をアカウントに結び付ける準備は、呼び出し元（`PaywallGate`）で済ませておく
public struct PaywallScreen: View {

    @Environment(\.appDependencies.purchaseClient) var purchaseClient
    @Environment(\.appDependencies.errorReportClient) var errorReportClient
    @Environment(SubscriptionStore.self) var subscriptionStore
    @LoadingState var loadingState

    @State var store: PaywallStore?

    /// 購入・復元を結び付けるアカウントのID
    let accountId: String
    let onClose: () -> Void

    public init(accountId: String, onClose: @escaping () -> Void) {
        self.accountId = accountId
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            PaywallView(
                phase: store?.phase ?? .loading,
                selectedPackageId: selectedPackageId,
                subscribedProductIdentifier: store?.subscribedProductIdentifier,
                onTapPurchase: tappedPurchaseButton,
                onTapRestore: tappedRestoreButton,
                onTapRetry: tappedRetryButton,
                onTapClose: onClose
            )
        }
        .fullScreenLoadingIndicator(loadingState)
        .alert(
            alertTitle,
            isPresented: isPresentedAlert,
            presenting: store?.alert
        ) { _ in
            Button(.localized("OK")) {}
        } message: { alert in
            Text(alertMessage(alert))
        }
        .task {
            await setupStoreAndLoad()
        }
    }

}

// MARK: UI定義

private extension PaywallScreen {

    var alertTitle: LocalizedStringResource {
        switch store?.alert {
        case .restoreNotFound, .restoreFailed:
            .localized("購入の復元")

        case .purchaseFailed, .purchasePending, nil:
            .localized("プレミアムプラン")
        }
    }

    func alertMessage(_ alert: PaywallAlert) -> LocalizedStringResource {
        switch alert {
        case .purchaseFailed:
            .localized("購入できませんでした。通信状態をご確認のうえ、もう一度お試しください。")

        case .purchasePending:
            .localized("購入の承認を待っています。承認されると、プレミアムプランの特典が使えるようになります。")

        case .restoreNotFound:
            .localized("復元できる購入が見つかりませんでした")

        case .restoreFailed:
            .localized("購入の復元に失敗しました。時間をおいて再度お試しください")
        }
    }

}

// MARK: プレゼンテーションロジック

private extension PaywallScreen {

    var selectedPackageId: Binding<String?> {
        Binding(
            get: { store?.selectedPackageId },
            set: { store?.selectedPackageId = $0 }
        )
    }

    var isPresentedAlert: Binding<Bool> {
        Binding(
            get: { store?.alert != nil },
            set: { isPresented in
                if !isPresented {
                    store?.alert = nil
                }
            }
        )
    }

    func setupStoreAndLoad() async {
        if store == nil {
            store = .init(
                accountId: accountId,
                purchaseClient: purchaseClient,
                errorReportClient: errorReportClient,
                subscriptionStore: subscriptionStore
            )
        }
        await store?.load()
    }

    func tappedPurchaseButton() {
        guard let store else { return }
        loadingState.task {
            await store.purchase()
        }
    }

    func tappedRestoreButton() {
        guard let store else { return }
        loadingState.task {
            await store.restore()
        }
    }

    func tappedRetryButton() {
        guard let store else { return }
        Task {
            await store.load()
        }
    }

}
