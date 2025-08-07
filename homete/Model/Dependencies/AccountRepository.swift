//
//  AccountListener.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import FirebaseAuth
import SwiftUI

struct AccountRepository {
    let signIn: @Sendable (String, String) async throws -> Void
    let signOut: @Sendable () throws -> Void
    let makeListener: @Sendable () -> AccountListenerStream
}

extension AccountRepository: DependencyClient {
    
    static let liveValue: AccountRepository = .init(signIn: { tokenId, nonce in
        
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: tokenId,
            rawNonce: nonce
        )
        let _ = try await Auth.auth().signIn(with: credential)
    }, signOut: {
        
        try Auth.auth().signOut()
    }, makeListener: {
        
        return Self.makeListener()
    })
    
    private static func makeListener() -> AccountListenerStream {
        let (stream, continuation) = AsyncStream<Account?>.makeStream()
        let token = Auth.auth().addStateDidChangeListener { auth, user in
            
            guard let user else {
                continuation.yield(nil)
                return
            }
            
            continuation.yield(.init(id: user.uid))
        }
        return .init(values: stream, listenerToken: token, continuation: continuation)
    }
    
    static let previewValue: AccountRepository = .init(
        signIn: { _, _ in },
        signOut: {},
        makeListener: {
            
            let (stream, continuation) = AsyncStream<Account?>.makeStream()
            return AccountListenerStream(values: stream,
                                         listenerToken: NSObject(),
                                         continuation: continuation)
        }
    )
}
