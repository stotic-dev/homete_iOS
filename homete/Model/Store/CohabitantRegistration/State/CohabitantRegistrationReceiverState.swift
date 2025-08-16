//
//  CohabitantRegistrationReceiverState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

final class CohabitantRegistrationReceiverState: CohabitantRegistrationStateBridge {
    
    private(set) var provider: any P2PServiceProvider
    let stateContinuation: AsyncStream<CohabitantRegistrationState>.Continuation
    
    init(
        provider: any P2PServiceProvider,
        stateContinuation: AsyncStream<CohabitantRegistrationState>.Continuation
    ) {
        
        self.provider = provider
        self.stateContinuation = stateContinuation
        self.provider.delegate = self
    }
    
    func didEnter() {
        
    }
    
    func next() -> CohabitantRegistrationSenderState? {
        
        return nil
    }
    
    func sendMessage<Message>(_ message: Message) throws where Message: Encodable {
        
    }
}
