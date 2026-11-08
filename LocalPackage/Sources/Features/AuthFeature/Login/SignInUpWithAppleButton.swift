//
//  SignInUpWithAppleButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/02.
//

import AuthenticationServices
import AuthFeatureUI
import HometeDomain
import SwiftUI

/// 「Appleでサインイン」ボタン。nonceを付けてリクエストし、結果をサインインの情報に変換して伝える
struct SignInUpWithAppleButton: View {

    @Environment(\.appDependencies.nonceGeneratorClient) var nonceGenerationClient
    @State var currentNonce: SignInWithAppleNonce?

    let onSignIn: (Result<SignInWithAppleResult, any Error>) async -> Void

    var body: some View {
        SignInWithAppleButtonContent(
            onRequest: { handleRequest(request: $0) },
            onCompletion: { handleCompletion(result: $0) }
        )
    }

}

private extension SignInUpWithAppleButton {

    func handleRequest(request: ASAuthorizationAppleIDRequest) {
        let nonce = nonceGenerationClient()
        request.requestedScopes = [.fullName]
        request.nonce = nonce.sha256
        currentNonce = nonce
    }

    func handleCompletion(result: Result<ASAuthorization, any Error>) {
        Task {
            switch result {
            case let .success(authorization):
                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let currentNonce else {
                    preconditionFailure("No sent sign in request.")
                }

                do {
                    let result = try SignInWithAppleResultFactory.make(appleIDCredential, currentNonce)
                    await onSignIn(.success(result))
                } catch {
                    await onSignIn(.failure(error))
                }

            case let .failure(error):
                print("failed sign in with apple: \(error)")
                if let error = error as? ASAuthorizationError,
                   error.code != .canceled {
                    await onSignIn(.failure(DomainError.failAuth))
                }
            }
        }
    }

}
