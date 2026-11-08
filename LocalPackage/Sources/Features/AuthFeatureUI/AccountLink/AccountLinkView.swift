//
//  AccountLinkView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// 匿名のアカウントをAppleアカウントと連携する画面のUI
/// - Note: サインインの処理は`AccountLinkScreen`が受け持ち、ボタンを差し込む
public struct AccountLinkView<SignInButton: View>: View {

    /// Paywallの前で開いたか。購入したプランを引き継げることを伝える
    let isBeforePurchase: Bool
    /// 閉じるボタンを出すか。連携を必須にしている場所では出さない
    let isClosable: Bool
    let onTapClose: () -> Void
    @ViewBuilder let signInButton: () -> SignInButton

    public init(
        isBeforePurchase: Bool,
        isClosable: Bool,
        onTapClose: @escaping () -> Void,
        @ViewBuilder signInButton: @escaping () -> SignInButton
    ) {
        self.isBeforePurchase = isBeforePurchase
        self.isClosable = isClosable
        self.onTapClose = onTapClose
        self.signInButton = signInButton
    }

    public var body: some View {
        VStack(spacing: .space16) {
            Spacer()
            HometteView(.point, size: .large)
            Text("Appleでサインイン", bundle: #bundle)
                .font(with: .headLineL)
            description
                .font(with: .body)
                .multilineTextAlignment(.center)
            Spacer()
            signInButton()
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
        if isBeforePurchase {
            Text("プランを購入するには、Appleでのサインインが必要です。機種変更しても、購入したプランを引き継げます", bundle: #bundle)
        } else {
            // パートナーの登録だけで始められると思われないよう、どこから開いても必要なことを伝える
            Text("家事の記録を始めるには、Appleでのサインインが必要です。機種変更しても、家事の記録を引き継げます", bundle: #bundle)
        }
    }

}

#Preview("AccountLinkView_連携が必須") {
    NavigationStack {
        AccountLinkView(isBeforePurchase: false, isClosable: false, onTapClose: {}) {
            SignInWithAppleButtonContent(onRequest: { _ in }, onCompletion: { _ in })
        }
    }
}

#Preview("AccountLinkView_設定") {
    NavigationStack {
        AccountLinkView(isBeforePurchase: false, isClosable: true, onTapClose: {}) {
            SignInWithAppleButtonContent(onRequest: { _ in }, onCompletion: { _ in })
        }
    }
}

#Preview("AccountLinkView_Paywallの前") {
    NavigationStack {
        AccountLinkView(isBeforePurchase: true, isClosable: true, onTapClose: {}) {
            SignInWithAppleButtonContent(onRequest: { _ in }, onCompletion: { _ in })
        }
    }
}
