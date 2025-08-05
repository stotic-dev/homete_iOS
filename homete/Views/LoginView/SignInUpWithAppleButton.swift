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
    @Environment(\.appDependencies.accountRepository) var accountRepository
    @Environment(\.appDependencies.nonceGeneratorRepository) var nonceGenerationClient
    @State var currentNonce: SignInWithAppleNonce?
    
    var body: some View {
        SignInWithAppleButton {
            let nonce = nonceGenerationClient()
            $0.requestedScopes = [.fullName]
            $0.nonce = nonce.sha256
            currentNonce = nonce
        } onCompletion: {
            switch $0 {
            case .success(let authorization):
                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let currentNonce else {
                    preconditionFailure("No sent sign in request.")
                }
                Task {
                    do {
                        guard let appleIDToken = appleIDCredential.identityToken else {
                            print("Unable to fetch identity token")
                            return
                        }
                        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                            return
                        }
                        _ = try await accountRepository.signIn(idTokenString, currentNonce.original)
                    }
                    catch {
                        print("error: \(error)")
                    }
                }
            case .failure(let error):
                print("error: \(error)")
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
    }
}

#Preview("light scheme") {
    SignInUpWithAppleButton()
        .frame(height: 48)
        .padding()
        .environment(\.colorScheme, .light)
}

#Preview("dark scheme") {
    SignInUpWithAppleButton()
        .frame(height: 48)
        .padding()
        .environment(\.colorScheme, .dark)
}
