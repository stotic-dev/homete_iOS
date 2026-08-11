//
//  RegistrationAccountView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

public struct RegistrationAccountView: View {

    @Environment(\.launchStateProxy) var launchStateProxy
    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(SubscriptionStore.self) var subscriptionStore
    @LoadingState var loadingState

    @State var inputUserName = UserName()
    /// 登録完了したアカウント（Paywallを閉じた後にログイン状態へ遷移させるために保持する）
    @State var registeredAccount: Account?
    @State var isShowPaywall = false
    let authInfo: AccountAuthResult
    let authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase

    public init(authInfo: AccountAuthResult, authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase) {
        self.authInfo = authInfo
        self.authSubscriptionSyncUseCase = authSubscriptionSyncUseCase
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: .space24) {
                VStack(spacing: .space16) {
                    Text("はじめまして！")
                        .font(with: .headLineM)
                    Text("まずはあなたのニックネームを教えてください")
                        .font(with: .body)
                        .foregroundStyle(.primary2)
                }
                VStack(spacing: .space8) {
                    Text("ユーザー名")
                        .font(with: .headLineS)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    UserNameInputTextField(userName: $inputUserName)
                    userNameCautionMessage()
                }
                Spacer(minLength: .space24)
                Button {
                    loadingState.task {
                        await tappedRegistrationButton()
                    }
                } label: {
                    Text("登録")
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .subPrimaryButtonStyle()
                .disabled(!inputUserName.canRegistration)
                Spacer()
                    .frame(height: .space24)
            }
            .padding(.horizontal, .space16)
            .navigationTitle("アカウント登録")
            .inlineNavigationBarTitleDisplayMode()
        }
        .fullScreenLoadingIndicator(loadingState)
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            onDismiss: { finishOnboarding() },
            content: { router.resolve(.paywall) }
        )
    }

}

private extension RegistrationAccountView {

    func userNameCautionMessage() -> some View {
        HStack(alignment: .top, spacing: .space8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.alert)
            Text("この名前はパートナーの画面でも表示されます。\n後からいつでも変更可能です。")
                .font(with: .caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

}

// MARK: プレゼンテーションロジック

private extension RegistrationAccountView {

    func tappedRegistrationButton() async {
        do {
            let account = try await authSubscriptionSyncUseCase.syncOnRegistered(
                auth: authInfo,
                userName: inputUserName
            )
            registeredAccount = account
            analyticsClient.log(.onboardingPaywallShown())
            isShowPaywall = true
        } catch {
            print("occurred error: \(error)")
        }
    }

    /// Paywallを閉じた後にログイン状態へ遷移する
    /// - Note: Paywallは購入を強制しないため、購入有無に関わらずここでオンボーディングを完了させる
    func finishOnboarding() {
        guard let registeredAccount else { return }
        analyticsClient.log(.onboardingPaywallClosed(isPremium: subscriptionStore.isPremium))
        launchStateProxy(.loggedIn(context: .init(account: registeredAccount)))
    }

}

#Preview("RegistrationAccountView_未入力") {
    let subscriptionStore = SubscriptionStore()
    RegistrationAccountView(
        authInfo: AccountAuthResult(id: ""),
        authSubscriptionSyncUseCase: .init(accountStore: AccountStore(), subscriptionStore: subscriptionStore)
    )
    .environment(subscriptionStore)
}

#Preview("RegistrationAccountView_入力済み") {
    let subscriptionStore = SubscriptionStore()
    RegistrationAccountView(
        authInfo: AccountAuthResult(id: "Test"),
        authSubscriptionSyncUseCase: .init(accountStore: AccountStore(), subscriptionStore: subscriptionStore)
    )
    .environment(subscriptionStore)
}
