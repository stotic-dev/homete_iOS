//
//  ASAuthorizationAppleIDRequest+Extension.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/31.
//

import AuthenticationServices
import HometeDomain

extension ASAuthorizationAppleIDRequest {

    func build(
        _ nonce: SignInWithAppleNonce
    ) {
        requestedScopes = [.fullName]
        self.nonce = nonce.sha256
    }
}
