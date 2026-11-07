//
//  PaywallView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// プレミアムプランの特典とプランの一覧を出し、購入・復元を受け付ける画面
/// - Note: 課金の画面なので、ほめっとは出さない（`ux-writing.md`）
struct PaywallView: View {

    let phase: PaywallPhase
    @Binding var selectedPackageId: String?
    /// 今契約しているプランのプロダクトID。契約していなければnil
    let subscribedProductIdentifier: String?
    let onTapPurchase: () -> Void
    let onTapRestore: () -> Void
    let onTapRetry: () -> Void
    let onTapClose: () -> Void

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.backgroundScreen)
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                // 取得の失敗・購入の完了は、画面の中に閉じるボタンがある
                if showsToolbarCloseButton {
                    NavigationBarButton(label: .close) {
                        onTapClose()
                    }
                }
            }
    }

}

// MARK: UI定義

private extension PaywallView {

    @ViewBuilder
    func content() -> some View {
        switch phase {
        case .loading:
            ProgressView()

        case let .loaded(offering):
            planListContent(offering: offering)

        case .loadFailed:
            PaywallPreparationErrorView(onTapRetry: onTapRetry, onTapClose: onTapClose)

        case .completed:
            PaywallCompletedContent(onTapClose: onTapClose)
        }
    }

    func planListContent(offering: PurchaseOffering) -> some View {
        ScrollView {
            VStack(spacing: .space32) {
                header
                PaywallBenefitListContent(benefits: PaywallBenefit.allCases)
                VStack(spacing: .space16) {
                    ForEach(offering.packages) { package in
                        PaywallPlanOptionContent(
                            package: package,
                            isSelected: package.id == selectedPackageId,
                            isSubscribed: package.productIdentifier == subscribedProductIdentifier,
                            onTap: { selectedPackageId = package.id }
                        )
                    }
                }
                actionButtons
                PaywallLegalNoticeContent()
            }
            .padding(.horizontal, .space16)
            .padding(.top, .space16)
            .padding(.bottom, .space24)
        }
    }

    var header: some View {
        VStack(spacing: .space16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(.iconDecorative)
                .accessibilityHidden(true)
            Text("プレミアムプラン", bundle: #bundle)
                .font(with: .headLineM)
                .accessibilityAddTraits(.isHeader)
            Text("家事の記録が、もっと便利になります。", bundle: #bundle)
                .font(with: .body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    var actionButtons: some View {
        VStack(spacing: .space16) {
            Button {
                onTapPurchase()
            } label: {
                Text(purchaseButtonTitle)
                    .padding(.vertical, .space8)
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .disabled(selectedPackageId == nil)
            Button(.localized("購入を復元")) {
                onTapRestore()
            }
            .font(with: .body)
            .foregroundStyle(.textSecondary)
        }
    }

    var showsToolbarCloseButton: Bool {
        switch phase {
        case .loading, .loaded:
            true

        case .loadFailed, .completed:
            false
        }
    }

    var purchaseButtonTitle: LocalizedStringResource {
        subscribedProductIdentifier == nil ? .localized("プレミアムプランに登録") : .localized("プランを変更")
    }

}

// MARK: Preview定義

#Preview("PaywallView_未登録") {
    @Previewable @State var selectedPackageId: String? = PurchasePackage.yearlyForPreview.id
    NavigationStack {
        PaywallView(
            phase: .loaded(.previewValue),
            selectedPackageId: $selectedPackageId,
            subscribedProductIdentifier: nil,
            onTapPurchase: {},
            onTapRestore: {},
            onTapRetry: {},
            onTapClose: {}
        )
    }
}

#Preview("PaywallView_プラン変更") {
    @Previewable @State var selectedPackageId: String? = PurchasePackage.yearlyForPreview.id
    NavigationStack {
        PaywallView(
            phase: .loaded(.previewValue),
            selectedPackageId: $selectedPackageId,
            subscribedProductIdentifier: PurchasePackage.monthlyForPreview.productIdentifier,
            onTapPurchase: {},
            onTapRestore: {},
            onTapRetry: {},
            onTapClose: {}
        )
    }
}

#Preview("PaywallView_取得失敗") {
    NavigationStack {
        PaywallView(
            phase: .loadFailed,
            selectedPackageId: .constant(nil),
            subscribedProductIdentifier: nil,
            onTapPurchase: {},
            onTapRestore: {},
            onTapRetry: {},
            onTapClose: {}
        )
    }
}

#Preview("PaywallView_購入完了") {
    NavigationStack {
        PaywallView(
            phase: .completed,
            selectedPackageId: .constant(nil),
            subscribedProductIdentifier: nil,
            onTapPurchase: {},
            onTapRestore: {},
            onTapRetry: {},
            onTapClose: {}
        )
    }
}

// スピナーは撮影ごとに回転角が変わりVRTがフレーキーになるため、スナップショットの対象から外す
#Preview("PaywallView_取得中") {
    NavigationStack {
        PaywallView(
            phase: .loading,
            selectedPackageId: .constant(nil),
            subscribedProductIdentifier: nil,
            onTapPurchase: {},
            onTapRestore: {},
            onTapRetry: {},
            onTapClose: {}
        )
    }
    #if canImport(Prefire)
    .prefireIgnored()
    #endif
}
