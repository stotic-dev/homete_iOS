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
    let onSignIn: (String, String) async -> Void
    
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
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let currentNonce else {
                
                preconditionFailure("No sent sign in request.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            Task {
                await onSignIn(idTokenString, currentNonce.original)
            }
        case .failure(let error):
            print("error: \(error)")
        }
    }
}

#Preview("light scheme") {
    SignInUpWithAppleButton { _, _ in }
        .frame(height: 48)
        .padding()
        .environment(\.colorScheme, .light)
        .environment(\.appDependencies, .previewValue)
}

#Preview("dark scheme") {
    SignInUpWithAppleButton { _, _ in }
        .frame(height: 48)
        .padding()
        .environment(\.colorScheme, .dark)
        .environment(\.appDependencies, .previewValue)
}
