//
//  SignInWithApple.swift
//

import AuthenticationServices
import HometeDomain

public final class SignInWithApple: NSObject, ASAuthorizationControllerDelegate {

    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, any Error>?

    public func callAsFunction(_ nonce: SignInWithAppleNonce) async throws -> ASAuthorizationAppleIDCredential {

        return try await withCheckedThrowingContinuation { continuation in

            self.continuation = continuation

            let authorizationController = ASAuthorizationController(
                authorizationRequests: [SignInWithAppleRequestFactory.make(nonce)]
            )
            authorizationController.delegate = self
            authorizationController.performRequests()
        }
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {

        if case let appleIDCredential as ASAuthorizationAppleIDCredential = authorization.credential {
            continuation?.resume(returning: appleIDCredential)
        }
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {

        continuation?.resume(throwing: error)
    }
}
