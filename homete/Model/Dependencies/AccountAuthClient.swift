//
//  AccountListener.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import FirebaseAuth

struct AccountAuthClient {
    
    let signIn: @Sendable (String, String) async throws -> AccountAuthResult
    let signOut: @Sendable () throws -> Void
    let makeListener: @Sendable () -> AccountListenerStream
    let reauthenticateWithApple: @Sendable (_ signInWithAppleResult: SignInWithAppleResult) async throws -> Void
    let revokeAppleToken: @Sendable (_ authorizationCode: String) async throws -> Void
    let deleteAccount: @Sendable () async throws -> Void
    
    init(
        signIn: @Sendable @escaping (String, String) async throws -> AccountAuthResult = { _, _ in .init(id: "id") },
        signOut: @Sendable @escaping () throws -> Void = {},
        makeListener: @Sendable @escaping () -> AccountListenerStream = {
            
            let (stream, continuation) = AsyncStream<AccountAuthResult?>.makeStream()
            return AccountListenerStream(values: stream,
                                         listenerToken: NSObject(),
                                         continuation: continuation)
        },
        reauthenticateWithApple: @Sendable @escaping (_: SignInWithAppleResult) async throws -> Void = { _ in },
        revokeAppleToken: @Sendable @escaping (_: String) async throws -> Void = { _ in },
        deleteAccount: @Sendable @escaping () async throws -> Void = {}
    ) {
        
        self.signIn = signIn
        self.signOut = signOut
        self.makeListener = makeListener
        self.reauthenticateWithApple = reauthenticateWithApple
        self.revokeAppleToken = revokeAppleToken
        self.deleteAccount = deleteAccount
    }
}

extension AccountAuthClient: DependencyClient {
    
    static let liveValue: AccountAuthClient = .init(
        signIn: { tokenId, nonce in
            
            try await signInWithApple(tokenId: tokenId, nonce: nonce)
        },
        signOut: {
            
            try Auth.auth().signOut()
        },
        makeListener: {
            
            return Self.makeListener()
        },
        reauthenticateWithApple: { signInWithAppleResult in
            
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: signInWithAppleResult.tokenId,
                rawNonce: signInWithAppleResult.nonce
            )
            guard let user = Auth.auth().currentUser else {
                
                throw DomainError.failAuth
            }
            try await user.reauthenticate(with: credential)
        },
        revokeAppleToken: { authorizationCode in
            
            try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCode)
        },
        deleteAccount: {
            
            guard let user = Auth.auth().currentUser else {
                throw DomainError.failAuth
            }
            try await user.delete()
        }
    )
    
    static let previewValue = AccountAuthClient()
}

private extension AccountAuthClient {
    
    static func signInWithApple(tokenId: String, nonce: String) async throws -> AccountAuthResult {
        
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: tokenId,
            rawNonce: nonce
        )
        let authInfo = try await Auth.auth().signIn(with: credential)
        return .init(id: authInfo.user.uid)
    }
    
    static func makeListener() -> AccountListenerStream {
        let (stream, continuation) = AsyncStream<AccountAuthResult?>.makeStream()
        let token = Auth.auth().addStateDidChangeListener { _, user in
            
            guard let user else {
                continuation.yield(nil)
                return
            }
            
            continuation.yield(.init(id: user.uid))
        }
        return .init(values: stream, listenerToken: token, continuation: continuation)
    }
}
