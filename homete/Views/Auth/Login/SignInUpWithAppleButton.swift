//
//  SignInUpWithAppleButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/02.
//

import AuthenticationServices
import SwiftUI

struct SignInUpWithAppleButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appDependencies.nonceGeneratorClient) var nonceGenerationClient
    @State var currentNonce: SignInWithAppleNonce?
    
    let onSignIn: (Result<SignInWithAppleResult, any Error>) async -> Void
    
    var body: some View {
        SignInWithAppleButton {
            handleRequest(request: $0)
        } onCompletion: {
            handleCompletion(result: $0)
        }
        .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
        .id(colorScheme)
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
            case .success(let authorization):
                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let currentNonce else {
                    
                    preconditionFailure("No sent sign in request.")
                }
                guard let appleIDToken = appleIDCredential.identityToken,
                      let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    
                    await onSignIn(.failure(DomainError.failAuth))
                    return
                }
                
                let result = SignInWithAppleResult(tokenId: idTokenString, nonce: currentNonce.original)
                await onSignIn(.success(result))
                
            case .failure(let error):
                print("failed sign in with apple: \(error)")
                if let error = error as? ASAuthorizationError,
                   error.code != .canceled {
                    
                    await onSignIn(.failure(DomainError.failAuth))
                }
            }
        }
    }
}

#Preview("SignInUpWithAppleButton_light scheme", traits: .sizeThatFitsLayout) {
    SignInUpWithAppleButton { _ in }
        .frame(height: 48)
        .padding()
        .environment(\.colorScheme, .light)
        .environment(\.appDependencies, .previewValue)
}

#Preview("SignInUpWithAppleButton_dark scheme", traits: .sizeThatFitsLayout) {
    SignInUpWithAppleButton { _ in }
        .frame(height: 48)
        .padding()
        .environment(\.colorScheme, .dark)
        .environment(\.appDependencies, .previewValue)
}
