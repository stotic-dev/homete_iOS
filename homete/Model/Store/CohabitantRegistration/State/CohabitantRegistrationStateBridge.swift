//
//  CohabitantRegistrationStateBridge.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

protocol CohabitantRegistrationStateBridge: P2PServiceDelegate {
    
    associatedtype NextState: CohabitantRegistrationStateBridge
        
    var provider: any P2PServiceProvider { get }
    var stateContinuation: AsyncStream<CohabitantRegistrationState>.Continuation { get }
    func didEnter()
    func next() -> NextState?
    func sendMessage<Message: Encodable>(_ message: Message) throws
}

extension CohabitantRegistrationStateBridge {
    
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
