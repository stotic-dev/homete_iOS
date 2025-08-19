//
//  CohabitantRegistrationStateBridge.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

protocol CohabitantRegistrationP2PSequence: P2PServiceDelegate {
            
    var provider: any P2PServiceProvider { get }
    var stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation { get }
    func next() -> (any CohabitantRegistrationP2PSequence)?
    func sendMessage<Message: Encodable>(_ message: Message) throws
}

extension CohabitantRegistrationP2PSequence {
    
    func didFoundDevice(peerID: MCPeerID) {}
    
    func didLostDevice(peerID: MCPeerID) {}
    
    func shouldAcceptInvitation(from peerID: MCPeerID) -> Bool {
        return true
    }
    
    func didConnect(to peerID: MCPeerID) {}
    
    func didDisconnect(from peerID: MCPeerID) {}
    
    func didReceiveData(_ data: Data, from peerID: MCPeerID) {
        
        preconditionFailure("Unexpected received data(data:\(data), peerID:\(peerID))")
    }
    
    func didReceiveError(_ error: any Error) {
        
        stateContinuation.yield(.error)
    }
}
