//
//  SignInWithAppleButtonContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/02.
//

import AuthenticationServices
import HometeModel
import SwiftUI

/// 「Appleでサインイン」ボタンの見た目
/// - Note: リクエストの組み立てと結果の扱いは`SignInUpWithAppleButton`が受け持つ
public struct SignInWithAppleButtonContent: View {

    @Environment(\.colorScheme) var colorScheme

    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, any Error>) -> Void

    public init(
        onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, any Error>) -> Void
    ) {
        self.onRequest = onRequest
        self.onCompletion = onCompletion
    }

    public var body: some View {
        SignInWithAppleButton {
            onRequest($0)
        } onCompletion: {
            onCompletion($0)
        }
        .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
        .id(colorScheme)
    }

}

#Preview("SignInUpWithAppleButton_light scheme", traits: .sizeThatFitsLayout) {
    SignInWithAppleButtonContent(onRequest: { _ in }, onCompletion: { _ in })
        .frame(height: 48)
        .padding()
        .environment(\.colorScheme, .light)
}

#Preview("SignInUpWithAppleButton_dark scheme", traits: .sizeThatFitsLayout) {
    SignInWithAppleButtonContent(onRequest: { _ in }, onCompletion: { _ in })
        .frame(height: 48)
        .padding()
        .environment(\.colorScheme, .dark)
}
