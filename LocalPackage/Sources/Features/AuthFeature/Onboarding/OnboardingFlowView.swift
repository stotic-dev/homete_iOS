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
/// - Note: 全ステップを終えた時点でログイン状態へ遷移する。購入・権限許可・パートナー登録は強制せずスキップできるが、
///         匿名のままパートナー登録を終えた人のApple連携だけはスキップできない
public struct OnboardingFlowView: View {

    @Environment(\.launchStateProxy) var launchStateProxy
    @Environment(\.appDependencies.notificationPermissionUseCase) var notificationPermissionUseCase
    @Environment(AccountStore.self) var accountStore

    @State var step = OnboardingStep.registration
    /// 実際に案内するステップの並び（案内が不要なステップは除かれる）
    @State var steps: [OnboardingStep]
    /// 通知の権限が未決定で、通知の案内を出すか
    @State var shouldGuideNotification = true
    /// オンボーディングを始めたときに匿名だったか
    /// - Note: 連携すると`authInfo`は匿名でなくなる。連携のステップを並びに残したまま次へ進めるよう、始めたときの値で並びを決める
    @State var startedAnonymously: Bool
    /// 登録が完了したアカウント（オンボーディング完了時にログイン状態へ渡すために保持する）
    @State var registeredAccount: Account?

    let authInfo: AccountAuthResult
    let authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase

    public init(authInfo: AccountAuthResult, authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase) {
        self.authInfo = authInfo
        self.authSubscriptionSyncUseCase = authSubscriptionSyncUseCase
        _startedAnonymously = State(initialValue: authInfo.isAnonymous)
        _steps = State(initialValue: OnboardingStep.steps(
            isAnonymous: authInfo.isAnonymous,
            shouldGuideNotification: true,
            hasRegisteredPartner: false
        ))
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

                case .partnerRegistration:
                    if let registeredAccount {
                        PartnerRegistrationScreen(account: registeredAccount) { hasRegisteredPartner in
                            completedPartnerRegistration(hasRegisteredPartner: hasRegisteredPartner)
                        }
                        // P2Pでの登録画面は、ログイン後と同じくログイン中のアカウントを環境から読む
                        .environment(
                            \.loginContext,
                            LoginContext(account: registeredAccount, isAnonymous: authInfo.isAnonymous)
                        )
                        .transition(stepTransition)
                    }

                case .accountLink:
                    // 匿名のままパートナーと使い始めると、機種変更で共有した家事ごと失われるため、閉じる導線を出さない
                    AccountLinkScreen(entry: .onboarding, onClose: nil) {
                        moveToNextStep()
                    }
                    .transition(stepTransition)

                case .premiumIntroduction:
                    PremiumIntroductionView {
                        moveToNextStep()
                    }
                    .transition(stepTransition)

                case .notificationPermission:
                    OnboardingNotificationPermissionGuideView {
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
        shouldGuideNotification = await notificationPermissionUseCase.shouldGuideOnOnboarding()
        steps = OnboardingStep.steps(
            isAnonymous: startedAnonymously,
            shouldGuideNotification: shouldGuideNotification,
            hasRegisteredPartner: false
        )
    }

    func completedRegistration(_ account: Account) {
        registeredAccount = account
        moveToNextStep()
    }

    /// パートナー登録の結果を受けて並びを組み立て直してから次へ進む（匿名なら次はApple連携になる）
    func completedPartnerRegistration(hasRegisteredPartner: Bool) {
        steps = OnboardingStep.steps(
            isAnonymous: startedAnonymously,
            shouldGuideNotification: shouldGuideNotification,
            hasRegisteredPartner: hasRegisteredPartner
        )
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

    /// - Note: パートナー登録で参加・P2P登録をするとグループIDが入り、Apple連携をすると匿名でなくなる。
    ///         どちらもオンボーディング中は起動状態に反映されないため、最新のアカウントと認証で入り直す
    func finishOnboarding() {
        guard let account = accountStore.account ?? registeredAccount else { return }
        launchStateProxy(.entered(LoginContext(account: account, isAnonymous: authInfo.isAnonymous)))
    }

}

// 初期ステップの見た目はRegistrationAccountViewのPreviewと同一のため、VRTの対象からは外す
#Preview {
    let subscriptionStore = SubscriptionStore()
    OnboardingFlowView(
        authInfo: AccountAuthResult(id: "Test"),
        authSubscriptionSyncUseCase: .init(
            accountStore: AccountStore(),
            cohabitantStore: CohabitantStore(),
            subscriptionStore: subscriptionStore,
            houseworkManager: .init(houseworkClient: .previewValue)
        )
    )
    .environment(subscriptionStore)
    .environment(AccountStore())
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
