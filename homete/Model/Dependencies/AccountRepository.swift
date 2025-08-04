//
//  AccountListener.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import FirebaseAuth
import SwiftUI

struct AccountRepository {
    let signIn: @Sendable (String, String) async throws -> Account
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
        let result = try await Auth.auth().signIn(with: credential)
        return .init(id: result.user.uid)
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
}
