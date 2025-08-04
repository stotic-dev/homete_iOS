//
//  AccountListenerStream.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/04.
//

import Foundation

struct AccountListenerStream {
    
    let values: AsyncStream<Account?>
    let listenerToken: any NSObjectProtocol
    private let continuation: AsyncStream<Account?>.Continuation
    
    init(values: AsyncStream<Account?>,
         listenerToken: any NSObjectProtocol,
         continuation: AsyncStream<Account?>.Continuation) {
        
        self.values = values
        self.listenerToken = listenerToken
        self.continuation = continuation
    }
    
    func stopListening() {
        
        continuation.finish()
    }
}
