//
//  CohabitantRegistrationStateBridge.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

protocol CohabitantRegistrationStateBridge: P2PServiceDelegate {
    
    /// 自分のデバイスの識別ID
    var myPeerID: MCPeerID { get }
    /// 接続済みの識別IDのリスト
    var connectedPeerIDs: Set<MCPeerID> { get }
    var provider: any P2PServiceProvider { get }
    var stateContinuation: AsyncStream<CohabitantRegistrationState>.Continuation { get }
}

extension CohabitantRegistrationStateBridge {
    
    func didFoundDevice(peerID: MCPeerID) {}
    
    func didLostDevice(peerID: MCPeerID) {}
    
    func shouldAcceptInvitation(from peerID: MCPeerID) -> Bool {
        return true
    }
    
    func didDisconnect(from peerID: MCPeerID) {}
    
    func didReceiveData(_ data: Data, from peerID: MCPeerID) {
        
        preconditionFailure("Unexpected received data(data:\(data), peerID:\(peerID))")
    }
    
    func didReceiveError(_ error: any Error) {
        
        stateContinuation.yield(.error)
    }
}

extension CohabitantRegistrationStateBridge {
    
    /// 接続先に指定のオブジェクトを送信する
    func sendMessageToALLDevice<Data: Encodable>(_ data: Data) async throws {
        
        let encodedData = try JSONEncoder().encode(data)
        await provider.send(encodedData, to: .init(connectedPeerIDs))
    }
    
    /// 指定のデバイスとの接続を切断する
    func disconnect(_ peerIDs: [MCPeerID]) {
        
        provider.finishSearching()
        provider.disconnect(to: peerIDs)
    }
}
