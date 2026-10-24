//
//  AccountLinkView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 匿名のアカウントをAppleアカウントと連携する画面のUI
struct AccountLinkView: View {

    let entry: AccountLinkEntry
    /// 閉じるボタンを出すか。連携を必須にしている場所では出さない
    let isClosable: Bool
    let onSignInWithApple: (Result<SignInWithAppleResult, any Error>) async -> Void
    let onTapClose: () -> Void

    var body: some View {
        VStack(spacing: .space16) {
            Spacer()
            HometteView(.point, size: .large)
            Text("Appleでサインイン", bundle: #bundle)
                .font(with: .headLineL)
            description
                .font(with: .body)
                .multilineTextAlignment(.center)
            Spacer()
            SignInUpWithAppleButton { result in
                await onSignInWithApple(result)
            }
            .frame(height: .space48)
            .cornerRadius(.radius12)
            Spacer()
                .frame(height: .space32)
        }
        .padding(.horizontal, .space16)
        .frame(maxWidth: .infinity)
        .background(.backgroundScreen)
        .trailingToolbarItem {
            if isClosable {
                NavigationBarButton(label: .close) {
                    onTapClose()
                }
            }
        }
    }

}

private extension AccountLinkView {

    @ViewBuilder
    var description: some View {
        switch entry {
        case .paywall:
            Text("プランを購入するには、Appleでのサインインが必要です。機種変更しても、購入したプランを引き継げます", bundle: #bundle)

        // パートナーの登録だけで始められると思われないよう、どこから開いても必要なことを伝える
        case .required, .onboarding, .todo, .setting:
            Text("家事の記録を始めるには、Appleでのサインインが必要です。機種変更しても、家事の記録を引き継げます", bundle: #bundle)
        }
    }

}

#Preview("AccountLinkView_連携が必須") {
    NavigationStack {
        AccountLinkView(entry: .required, isClosable: false, onSignInWithApple: { _ in }, onTapClose: {})
    }
    .environment(\.appDependencies, .previewValue)
}

#Preview("AccountLinkView_設定") {
    NavigationStack {
        AccountLinkView(entry: .setting, isClosable: true, onSignInWithApple: { _ in }, onTapClose: {})
    }
    .environment(\.appDependencies, .previewValue)
}

#Preview("AccountLinkView_Paywallの前") {
    NavigationStack {
        AccountLinkView(entry: .paywall, isClosable: true, onSignInWithApple: { _ in }, onTapClose: {})
    }
    .environment(\.appDependencies, .previewValue)
}
