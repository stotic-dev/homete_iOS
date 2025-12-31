//
//  SignInWithAppleClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/31.
//

import AuthenticationServices

struct SignInWithAppleClient {
    let reauthentication: @MainActor (_ nonce: SignInWithAppleNonce) async throws -> SignInWithAppleResult
    
    init(reauthentication: @MainActor @escaping (_ nonce: SignInWithAppleNonce) async throws -> SignInWithAppleResult = { _ in preconditionFailure() }) {
        
        self.reauthentication = reauthentication
    }
}

extension SignInWithAppleClient: DependencyClient {
    
    static let liveValue = SignInWithAppleClient { nonce in
        
        let signInWithApple = SignInWithApple()
        let appleIDCredential = try await signInWithApple(nonce.sha256)
        
        // TODO: SignInWithAppleResult生成処理はConverterに移譲する
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetdch identify token.")
            throw DomainError.failAuth
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
            throw DomainError.failAuth
        }
        
        guard let authorizationCode = appleIDCredential.authorizationCode,
        let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
            throw DomainError.failAuth
        }
        return .init(tokenId: idTokenString, nonce: nonce.original, authorizationCode: authCodeString)
    }
    
    static let previewValue = SignInWithAppleClient()
}

private final class SignInWithApple: NSObject, ASAuthorizationControllerDelegate {
    
    private var continuation : CheckedContinuation<ASAuthorizationAppleIDCredential, any Error>?
    
    func callAsFunction(_ nonce: String) async throws -> ASAuthorizationAppleIDCredential {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            self.continuation = continuation
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName]
            request.nonce = nonce
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.performRequests()
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        
        if case let appleIDCredential as ASAuthorizationAppleIDCredential = authorization.credential {
            continuation?.resume(returning: appleIDCredential)
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        
        continuation?.resume(throwing: error)
    }
}
