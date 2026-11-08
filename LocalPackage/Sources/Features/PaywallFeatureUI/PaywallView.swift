//
//  PaywallView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// プレミアムプランの特典とプランの一覧を出し、購入・復元を受け付ける画面
/// - Note: 課金の画面なので、ほめっとは出さない（`ux-writing.md`）
public struct PaywallView: View {

    let phase: PaywallPhase
    @Binding var selectedPackageId: String?
    /// 今契約しているプランのプロダクトID。契約していなければnil
    let subscribedProductIdentifier: String?
    let onTapPurchase: () -> Void
    let onTapRestore: () -> Void
    let onTapRetry: () -> Void
    let onTapClose: () -> Void

    public init(
        phase: PaywallPhase,
        selectedPackageId: Binding<String?>,
        subscribedProductIdentifier: String?,
        onTapPurchase: @escaping () -> Void,
        onTapRestore: @escaping () -> Void,
        onTapRetry: @escaping () -> Void,
        onTapClose: @escaping () -> Void
    ) {
        self.phase = phase
        _selectedPackageId = selectedPackageId
        self.subscribedProductIdentifier = subscribedProductIdentifier
        self.onTapPurchase = onTapPurchase
        self.onTapRestore = onTapRestore
        self.onTapRetry = onTapRetry
        self.onTapClose = onTapClose
    }

    public var body: some View {
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
                PaywallHeroContent()
                PaywallBenefitListContent(benefits: PaywallBenefit.allCases)
                VStack(spacing: .space16) {
                    ForEach(offering.packages) { package in
                        let isSubscribed = package.productIdentifier == subscribedProductIdentifier
                        PaywallPlanOptionContent(
                            package: package,
                            isSelected: package.id == selectedPackageId,
                            isSubscribed: isSubscribed,
                            // 1か月あたりがいちばん安い年額を勧める。契約中なら勧めない
                            isRecommended: package.period == .yearly && !isSubscribed,
                            onTap: { selectedPackageId = package.id }
                        )
                    }
                }
                VStack(spacing: .space16) {
                    Button(.localized("購入を復元")) {
                        onTapRestore()
                    }
                    .font(with: .body)
                    .foregroundStyle(.textSecondary)
                    PaywallLegalNoticeContent()
                }
            }
            .padding(.horizontal, .space16)
            .padding(.top, .space16)
            .padding(.bottom, .space24)
        }
        .softTopScrollEdgeEffect()
        // 特典を読んでいる間も申し込めるよう、購入ボタンは下に固定する
        .safeAreaInset(edge: .bottom) {
            purchaseButton
        }
    }

    var purchaseButton: some View {
        Button {
            onTapPurchase()
        } label: {
            Text(purchaseButtonTitle)
                .padding(.vertical, .space8)
                .frame(maxWidth: .infinity)
        }
        .primaryButtonStyle()
        .disabled(selectedPackageId == nil)
        .padding(.horizontal, .space16)
        .padding(.vertical, .space8)
        .background(.backgroundScreen)
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
            phase: .loaded(PurchaseOffering(packages: [.yearlyForPreview, .monthlyForPreview])),
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
            phase: .loaded(PurchaseOffering(packages: [.yearlyForPreview, .monthlyForPreview])),
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
