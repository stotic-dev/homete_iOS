//
//  SignInWithAppleClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/31.
//

import AuthenticationServices

struct SignInWithAppleClient {
    let reauthentication: @MainActor (_ nonce: SignInWithAppleNonce) async throws -> SignInWithAppleResult
    
    init(
        reauthentication: @MainActor @escaping (_ nonce: SignInWithAppleNonce)
        async throws -> SignInWithAppleResult = { _ in preconditionFailure() }
    ) {
        
        self.reauthentication = reauthentication
    }
}

extension SignInWithAppleClient: DependencyClient {
    
    static let liveValue = SignInWithAppleClient { nonce in
        
        let signInWithApple = SignInWithApple()
        let appleIDCredential = try await signInWithApple(nonce)
        return try SignInWithAppleResultFactory.make(appleIDCredential, nonce)
    }
    
    static let previewValue = SignInWithAppleClient()
}
