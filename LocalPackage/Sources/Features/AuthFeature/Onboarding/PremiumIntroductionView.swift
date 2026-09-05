//
//  PremiumIntroductionView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// オンボーディングでプレミアムプランの特典を説明し、Paywallへの導線を提供する画面
struct PremiumIntroductionView: View {

    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(SubscriptionStore.self) var subscriptionStore

    @State var isShowPaywall = false

    /// この画面での操作が終わり、次のステップへ進むときに呼ばれる
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: .space32) {
            VStack(spacing: .space16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.primary3)
                Text("プレミアムプランのご案内")
                    .font(with: .headLineM)
                Text("homeauは無料のままでもすべての家事管理機能をお使いいただけます。\nもっと快適に使いたい方向けに、プレミアムプランをご用意しています。")
                    .font(with: .body)
                    .foregroundStyle(.primary2)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: .space24) {
                benefitRow(
                    systemImage: "rectangle.slash",
                    title: "広告が表示されません",
                    description: "ダッシュボードのバナー広告が消え、家事の記録に集中できます。"
                )
                benefitRow(
                    systemImage: "sparkles",
                    title: "今後追加される機能もすべて使えます",
                    description: "プレミアム限定の新機能が増えても、追加の料金はかかりません。"
                )
            }
            Spacer(minLength: .space24)
            VStack(spacing: .space16) {
                Button {
                    tappedShowPaywallButton()
                } label: {
                    Text("プランを見る")
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .subPrimaryButtonStyle()
                Button("あとで決める") {
                    tappedSkipButton()
                }
                .font(with: .body)
                .foregroundStyle(.primary2)
            }
            Spacer()
                .frame(height: .space24)
        }
        .padding(.horizontal, .space16)
        .padding(.top, .space32)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            onAppearView()
        }
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            onDismiss: { dismissedPaywall() },
            content: { router.resolve(.paywall) }
        )
    }

}

// MARK: UI定義

private extension PremiumIntroductionView {

    func benefitRow(systemImage: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: .space16) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.primary3)
                .frame(width: .space32)
            VStack(alignment: .leading, spacing: .space4) {
                Text(title)
                    .font(with: .headLineS)
                Text(description)
                    .font(with: .caption)
                    .foregroundStyle(.primary2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

}

// MARK: プレゼンテーションロジック

private extension PremiumIntroductionView {

    func onAppearView() {
        analyticsClient.log(.onboarding(.premiumIntroductionShown))
    }

    func tappedShowPaywallButton() {
        analyticsClient.log(.onboarding(.paywallShown))
        isShowPaywall = true
    }

    func tappedSkipButton() {
        analyticsClient.log(.onboarding(.premiumIntroductionSkipped))
        onNext()
    }

    /// Paywallを閉じた後は、購入有無に関わらず次のステップへ進む
    func dismissedPaywall() {
        analyticsClient.log(.onboarding(.paywallClosed(isPremium: subscriptionStore.isPremium)))
        onNext()
    }

}

#Preview("PremiumIntroductionView") {
    PremiumIntroductionView {}
        .environment(SubscriptionStore())
}
