//
//  DebugOnboardingScreen.swift
//  LocalPackage
//

#if DEBUG

import AuthFeature
import HometeDomain
import HometeUI
import SwiftUI

/// オンボーディング（アカウント登録→特典説明→通知権限）を実データに影響を与えずに確認するためのデバッグ画面
/// - Note: Store類だけでなく`AppDependencies`と`RouteResolver`もこの画面用に差し替えている。
///         そのためFirestore・RevenueCatへの書き込み、Analyticsの送信、実機の通知権限ダイアログ表示、
///         APNsへの登録、本物のPaywall表示はいずれも発生しない
struct DebugOnboardingScreen: View {

    @Environment(\.dismiss) var dismiss

    @State var accountStore = AccountStore()
    @State var subscriptionStore = SubscriptionStore()
    /// 本物の起動状態を書き換えないためのダミー。ログイン状態への遷移要求はこのデバッグ画面を閉じる操作として扱う
    @State var launchState = LaunchState.launching

    var body: some View {
        ZStack(alignment: .topTrailing) {
            OnboardingFlowView(
                authInfo: AccountAuthResult(id: "debug-onboarding"),
                authSubscriptionSyncUseCase: .init(
                    accountStore: accountStore,
                    subscriptionStore: subscriptionStore
                )
            )
            .environment(subscriptionStore)
            .environment(\.launchStateProxy, .init(launchState: $launchState))
            // 全クライアントが`previewValue`（何もしない実装）の依存に差し替えて、実環境への副作用を遮断する
            .environment(\.appDependencies, .previewValue)
            .environment(\.routeResolver, .debugOnboarding)
            .onChange(of: launchState) {
                dismiss()
            }
            // 実フローのオンボーディングは閉じる導線を持たないため、途中で抜けられるようデバッグ画面側で重ねる
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

private extension RouteResolver {

    /// デバッグ画面から本物のPaywall（RevenueCatの購入フロー）へ入らないようにするためのResolver
    static let debugOnboarding = RouteResolver { route in
        DebugRoutePlaceholderView(route: route)
    }

}

/// 遷移が呼ばれたことだけを確認するためのダミー画面
private struct DebugRoutePlaceholderView: View {

    @Environment(\.dismiss) var dismiss

    let route: AppRoute

    var body: some View {
        VStack(spacing: .space16) {
            Text("デバッグ用のダミー画面")
                .font(with: .headLineM)
            Text(String(describing: route))
                .font(with: .body)
                .foregroundStyle(.primary2)
            Button("閉じる") {
                dismiss()
            }
            .subPrimaryButtonStyle()
        }
        .padding(.horizontal, .space16)
    }

}

#endif
