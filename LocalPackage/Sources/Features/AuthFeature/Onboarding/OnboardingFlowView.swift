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
    @Environment(\.appDependencies.notificationPermissionUseCase) var notificationPermissionUseCase

    @State var step = OnboardingStep.registration
    /// 実際に案内するステップの並び（案内が不要なステップは除かれる）
    @State var steps = OnboardingStep.allCases
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
                        moveToNextStep()
                    }
                    .transition(stepTransition)

                case .notificationPermission:
                    NotificationPermissionGuideView {
                        moveToNextStep()
                    }
                    .transition(stepTransition)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            OnboardingProgressIndicator(steps: steps, currentStep: step)
        }
        .padding(.bottom, .space16)
        .animation(.spring, value: step)
        .task {
            await loadSteps()
        }
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

    /// 案内が不要なステップを除いて、進捗の分母を実際に表示する画面数と一致させる
    func loadSteps() async {
        let shouldGuideNotification = await notificationPermissionUseCase.shouldGuideOnOnboarding()
        guard !shouldGuideNotification else { return }

        steps = OnboardingStep.allCases.filter { $0 != .notificationPermission }
    }

    func completedRegistration(_ account: Account) {
        registeredAccount = account
        moveToNextStep()
    }

    /// 次のステップへ進む。残りのステップがなければオンボーディングを完了する
    func moveToNextStep() {
        let nextIndex = (steps.firstIndex(of: step) ?? 0) + 1
        guard steps.indices.contains(nextIndex) else {
            finishOnboarding()
            return
        }

        step = steps[nextIndex]
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
