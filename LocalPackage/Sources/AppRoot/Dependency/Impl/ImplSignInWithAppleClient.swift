//
//  ImplSignInWithAppleClient.swift
//

import AuthenticationServices
import HometeDomain
import HometeInfrastructure

extension SignInWithAppleClient {

    static let liveValue = SignInWithAppleClient { nonce in

        let signInWithApple = SignInWithApple()
        let appleIDCredential = try await signInWithApple(nonce)
        return try SignInWithAppleResultFactory.make(appleIDCredential, nonce)
    }
}
