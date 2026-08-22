//
//  OnboardingFlowView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// アカウント登録直後のオンボーディングを順番に案内する画面
/// - Note: 全ステップを終えた時点でログイン状態へ遷移する。各ステップは購入・権限許可を強制せずスキップできる
public struct OnboardingFlowView: View {

    @Environment(\.launchStateProxy) var launchStateProxy

    @State var step = OnboardingStep.registration
    /// 登録が完了したアカウント（オンボーディング完了時にログイン状態へ渡すために保持する）
    @State var registeredAccount: Account?

    let authInfo: AccountAuthResult
    let authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase

    public init(authInfo: AccountAuthResult, authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase) {
        self.authInfo = authInfo
        self.authSubscriptionSyncUseCase = authSubscriptionSyncUseCase
    }

    public var body: some View {
        VStack(spacing: .space8) {
            ZStack {
                switch step {
                case .registration:
                    RegistrationAccountView(
                        authInfo: authInfo,
                        authSubscriptionSyncUseCase: authSubscriptionSyncUseCase
                    ) { account in
                        completedRegistration(account)
                    }

                case .premiumIntroduction:
                    PremiumIntroductionView {
                        step = .notificationPermission
                    }
                    .transition(stepTransition)

                case .notificationPermission:
                    NotificationPermissionGuideView {
                        finishOnboarding()
                    }
                    .transition(stepTransition)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            OnboardingProgressIndicator(currentStep: step)
        }
        .padding(.bottom, .space16)
        .animation(.spring, value: step)
    }

}

private extension OnboardingFlowView {

    var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .push(from: .trailing),
            removal: .opacity
        )
    }

}

// MARK: プレゼンテーションロジック

private extension OnboardingFlowView {

    func completedRegistration(_ account: Account) {
        registeredAccount = account
        step = .premiumIntroduction
    }

    func finishOnboarding() {
        guard let registeredAccount else { return }
        launchStateProxy(.loggedIn(context: .init(account: registeredAccount)))
    }

}

// 初期ステップの見た目はRegistrationAccountViewのPreviewと同一のため、VRTの対象からは外す
#Preview {
    let subscriptionStore = SubscriptionStore()
    OnboardingFlowView(
        authInfo: AccountAuthResult(id: "Test"),
        authSubscriptionSyncUseCase: .init(accountStore: AccountStore(), subscriptionStore: subscriptionStore)
    )
    .environment(subscriptionStore)
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
