//
//  SignInWithAppleRequestFactory.swift
//

import AuthenticationServices
import HometeDomain

enum SignInWithAppleRequestFactory {

    static func make(_ nonce: SignInWithAppleNonce) -> ASAuthorizationAppleIDRequest {

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName]
        request.nonce = nonce.sha256
        return request
    }
}
