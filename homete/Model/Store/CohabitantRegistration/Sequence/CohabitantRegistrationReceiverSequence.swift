//
//  CohabitantRegistrationReceiverState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

final class CohabitantRegistrationReceiverSequence: CohabitantRegistrationP2PSequence {
    
    private let connectedPeerId: MCPeerID
    private(set) var provider: any P2PServiceProvider
    let stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    
    init(
        connectedPeerId: MCPeerID,
        provider: any P2PServiceProvider,
        stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    ) {
        
        print("didEnter CohabitantRegistrationReceiverSequence")
        self.connectedPeerId = connectedPeerId
        self.provider = provider
        self.stateContinuation = stateContinuation
        self.provider.delegate = self
    }
    
    func next() -> (any CohabitantRegistrationP2PSequence)? {
        
        provider.finish()
        return nil
    }
    
    func didDisconnect(from peerID: MCPeerID) {
        
        stateContinuation.yield(.error)
    }
    
    func sendMessage<Message>(_ message: Message) throws where Message: Encodable {
        
        print("\(#file) \(#function)")
        let encodedData = try JSONEncoder().encode(message)
        provider.send(encodedData, to: [connectedPeerId])
    }
    
    func didReceiveData(_ data: Data, from peerID: MCPeerID) {
        
        print("\(#file) \(#function)")
        if let confirmMessage = try? JSONDecoder().decode(CohabitantRegistrationConfirmMessage.self, from: data),
           confirmMessage.response == .ok {
            
            stateContinuation.yield(.readyToShareAccountId)
        }
        else if let decodedData = try? JSONDecoder().decode(CohabitantIdShareMessage.self, from: data) {
            
            stateContinuation.yield(.receivedId(decodedData))
        }
        else {
            
            preconditionFailure("did received unexpected data: \(data)")
        }
    }
}
