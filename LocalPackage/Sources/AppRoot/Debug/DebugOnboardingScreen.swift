//
//  DebugOnboardingScreen.swift
//  LocalPackage
//

#if DEBUG

import AuthFeature
import HometeDomain
import SwiftUI

/// オンボーディング（アカウント登録→Paywall）を実データに影響を与えずに確認するためのデバッグ画面
/// - Note: Store類は`previewValue`のクライアントで生成しているため、登録操作をしてもFirestoreやRevenueCatには一切書き込まれない
struct DebugOnboardingScreen: View {

    @Environment(\.dismiss) var dismiss

    @State var accountStore = AccountStore()
    @State var subscriptionStore = SubscriptionStore()
    /// 本物の起動状態を書き換えないためのダミー。ログイン状態への遷移要求はこのデバッグ画面を閉じる操作として扱う
    @State var launchState = LaunchState.launching

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RegistrationAccountView(
                authInfo: AccountAuthResult(id: "debug-onboarding"),
                authSubscriptionSyncUseCase: .init(
                    accountStore: accountStore,
                    subscriptionStore: subscriptionStore
                )
            )
            .environment(subscriptionStore)
            .environment(\.launchStateProxy, .init(launchState: $launchState))
            .onChange(of: launchState) {
                dismiss()
            }
            // 実フローの登録画面は閉じる導線を持たないため、途中で抜けられるようデバッグ画面側で重ねる
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .padding(.horizontal, .space16)
                    .padding(.top, .space8)
            }
        }
    }

}

#endif
