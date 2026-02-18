//
//  SignInWithAppleClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/31.
//

import AuthenticationServices
import HometeDomain

extension SignInWithAppleClient {
    
    static let liveValue = SignInWithAppleClient { nonce in
        
        let signInWithApple = SignInWithApple()
        let appleIDCredential = try await signInWithApple(nonce)
        return try SignInWithAppleResultFactory.make(appleIDCredential, nonce)
    }
}
