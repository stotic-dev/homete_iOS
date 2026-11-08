//
//  PremiumIntroductionScreen.swift
//  LocalPackage
//

import AuthFeatureUI
import HometeDomain
import HometeUI
import SwiftUI

/// オンボーディングでプレミアムプランの特典を説明し、Paywallへの導線を提供する画面
struct PremiumIntroductionScreen: View {

    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.analyticsClient) var analyticsClient

    @State var isShowPaywall = false

    /// この画面での操作が終わり、次のステップへ進むときに呼ばれる
    let onNext: () -> Void

    var body: some View {
        PremiumIntroductionView(
            onTapShowPaywall: { isShowPaywall = true },
            onTapSkip: { tappedSkipButton() }
        )
        .onAppear {
            onAppearView()
        }
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            onDismiss: { dismissedPaywall() },
            content: { router.resolve(.paywall(step: .onboarding)) }
        )
        .trackScreenView(.onboardingPremiumIntroduction)
    }

}

// MARK: プレゼンテーションロジック

private extension PremiumIntroductionScreen {

    func onAppearView() {
        analyticsClient.log(.onboarding(.premiumIntroductionShown))
    }

    func tappedSkipButton() {
        analyticsClient.log(.onboarding(.premiumIntroductionSkipped))
        onNext()
    }

    /// Paywallを閉じた後は、購入有無に関わらず次のステップへ進む
    func dismissedPaywall() {
        onNext()
    }

}
