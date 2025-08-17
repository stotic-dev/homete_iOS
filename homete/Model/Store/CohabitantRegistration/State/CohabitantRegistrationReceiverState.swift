//
//  CohabitantRegistrationReceiverState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

final class CohabitantRegistrationReceiverState: CohabitantRegistrationStateBridge {
    
    private(set) var provider: any P2PServiceProvider
    let stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    
    init(
        provider: any P2PServiceProvider,
        stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    ) {
        
        self.provider = provider
        self.stateContinuation = stateContinuation
        self.provider.delegate = self
    }
    
    func didEnter() {
        
    }
    
    func next() -> (any CohabitantRegistrationStateBridge)? {
        
        return nil
    }
    
    func didDisconnect(from peerID: MCPeerID) {
        
        stateContinuation.yield(.error)
    }
    
    func sendMessage<Message>(_ message: Message) throws where Message: Encodable {
        
    }
    
    func didReceiveData(_ data: Data, from peerID: MCPeerID) {
        
        do {
            
            let decodedData = try JSONDecoder().decode(CohabitantIdMessage.self, from: data)
            stateContinuation.yield(.receivedId(decodedData))
        }
        catch {
            
            stateContinuation.yield(.error)
        }
    }
}
