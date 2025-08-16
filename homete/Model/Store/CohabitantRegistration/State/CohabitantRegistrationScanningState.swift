//
//  CohabitantRegistrationScanningState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

final class CohabitantRegistrationScanningState: CohabitantRegistrationStateBridge {
    
    let myPeerID: MCPeerID
    private(set) var connectedPeerIDs: Set<MCPeerID> = []
    private(set) var provider: any P2PServiceProvider
    let stateContinuation: AsyncStream<CohabitantRegistrationState>.Continuation
    
    init(
        myPeerID: MCPeerID,
        cohabitantPeerIDs: Set<MCPeerID>,
        provider: any P2PServiceProvider,
        stateContinuation: AsyncStream<CohabitantRegistrationState>.Continuation
    ) {
        
        self.myPeerID = myPeerID
        self.connectedPeerIDs = cohabitantPeerIDs
        self.provider = provider
        self.stateContinuation = stateContinuation
        self.provider.delegate = self
    }
    
    func didConnect(to peerID: MCPeerID) {
        
        connectedPeerIDs.insert(peerID)
    }
}
