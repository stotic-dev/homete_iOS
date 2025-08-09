//
//  AccountListenerStream.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/04.
//

import Foundation

struct AccountListenerStream {
    
    let values: AsyncStream<AccountAuthResult?>
    let listenerToken: any NSObjectProtocol
    private let continuation: AsyncStream<AccountAuthResult?>.Continuation
    
    init(values: AsyncStream<AccountAuthResult?>,
         listenerToken: any NSObjectProtocol,
         continuation: AsyncStream<AccountAuthResult?>.Continuation) {
        
        self.values = values
        self.listenerToken = listenerToken
        self.continuation = continuation
    }
    
    func stopListening() {
        
        continuation.finish()
    }
}
