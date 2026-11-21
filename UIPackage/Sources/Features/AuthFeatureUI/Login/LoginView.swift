//
//  LoginView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import HometeModel
import HometeResources
import HometeUI
import SwiftUI

/// Appleアカウントでログインする画面
/// - Note: サインインの処理は`LoginScreen`が受け持ち、ボタンを差し込む
public struct LoginView<SignInButton: View>: View {

    @ViewBuilder let signInButton: () -> SignInButton

    public init(@ViewBuilder signInButton: @escaping () -> SignInButton) {
        self.signInButton = signInButton
    }

    public var body: some View {
        VStack(spacing: .space16) {
            HometteView(.wave, size: .large)
            Text("\(Constants.appName)へようこそ", bundle: #bundle)
                .font(with: .headLineL)
            Text("Appleアカウントで、すぐに始められます", bundle: #bundle)
                .font(with: .body)
            signInButton()
                .frame(height: .space48)
                .cornerRadius(.radius12)
            Spacer()
            // swiftlint:disable:next line_length
            Text(
                "続行すると、[利用規約](https://stotic-dev.github.io/homete_iOS/terms.html)と[プライバシーポリシー](https://stotic-dev.github.io/homete_iOS/privacy.html)に同意したことになります。",
                bundle: #bundle
            )
            .font(with: .caption)
            .foregroundStyle(.textSecondary)
            .tint(.textAccent)
            Spacer()
                .frame(height: .space32)
        }
        .padding(.horizontal, .space16)
        .ignoresSafeArea(edges: [.bottom])
    }

}

#Preview {
    LoginView {
        SignInWithAppleButtonContent(onRequest: { _ in }, onCompletion: { _ in })
    }
}
