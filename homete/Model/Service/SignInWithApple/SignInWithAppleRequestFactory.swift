//
//  SignInWithAppleRequestFactory.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/31.
//

import AuthenticationServices

enum SignInWithAppleRequestFactory {
    
    static func make(_ nonce: SignInWithAppleNonce) -> ASAuthorizationAppleIDRequest {
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.build(nonce)
        return request
    }
}

extension ASAuthorizationAppleIDRequest {
    
    func build(
        _ nonce: SignInWithAppleNonce
    ) {
        
        requestedScopes = [.fullName]
        self.nonce = nonce.sha256
    }
}
