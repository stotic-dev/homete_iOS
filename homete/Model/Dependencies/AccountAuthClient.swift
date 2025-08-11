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
}

extension AccountAuthClient: DependencyClient {
    
    static let liveValue: AccountAuthClient = .init(signIn: { tokenId, nonce in
        
        try await signInWithApple(tokenId: tokenId, nonce: nonce)
    }, signOut: {
        
        try Auth.auth().signOut()
    }, makeListener: {
        
        return Self.makeListener()
    })
    
    static let previewValue: AccountAuthClient = .init(
        signIn: { _, _ in .init(id: "id", displayName: "name") },
        signOut: {},
        makeListener: {
            
            let (stream, continuation) = AsyncStream<AccountAuthResult?>.makeStream()
            return AccountListenerStream(values: stream,
                                         listenerToken: NSObject(),
                                         continuation: continuation)
        }
    )
}

private extension AccountAuthClient {
    
    static func signInWithApple(tokenId: String, nonce: String) async throws -> AccountAuthResult {
        
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: tokenId,
            rawNonce: nonce
        )
        let authInfo = try await Auth.auth().signIn(with: credential)
        
        if Auth.auth().currentUser?.displayName == nil,
           authInfo.user.displayName != nil {
            
            try await Auth.auth().updateCurrentUser(authInfo.user)
        }
        
        return .init(id: authInfo.user.uid, displayName: Auth.auth().currentUser?.displayName)
    }
    
    static func makeListener() -> AccountListenerStream {
        let (stream, continuation) = AsyncStream<AccountAuthResult?>.makeStream()
        let token = Auth.auth().addStateDidChangeListener { _, user in
            
            guard let user else {
                continuation.yield(nil)
                return
            }
            
            continuation.yield(.init(id: user.uid, displayName: user.displayName))
        }
        return .init(values: stream, listenerToken: token, continuation: continuation)
    }
}
