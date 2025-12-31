//
//  SignInWithAppleResultFactory.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/31.
//

import AuthenticationServices

enum SignInWithAppleResultFactory {
    static func make(
        _ credential: ASAuthorizationAppleIDCredential,
        _ nonce: SignInWithAppleNonce
    ) throws -> SignInWithAppleResult {
        
        guard let appleIDToken = credential.identityToken else {
            print("Unable to fetdch identify token.")
            throw DomainError.failAuth
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
            throw DomainError.failAuth
        }
        
        guard let authorizationCode = credential.authorizationCode,
              let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
            throw DomainError.failAuth
        }
        
        return .init(
            tokenId: idTokenString,
            nonce: nonce.original,
            authorizationCode: authCodeString
        )
    }
}
