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
    let stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    
    init(
        myPeerID: MCPeerID,
        provider: any P2PServiceProvider,
        stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    ) {
        
        self.myPeerID = myPeerID
        self.provider = provider
        self.stateContinuation = stateContinuation
        self.provider.delegate = self
    }
    
    func didEnter() {
        
        print("start searching(self id: \(myPeerID))")
        provider.startSearching()
    }
    
    func didConnect(to peerID: MCPeerID) {
        
        connectedPeerIDs.insert(peerID)
        stateContinuation.yield(
            .searching(connectedDeviceNameList: connectedPeerIDs.map(\.displayName))
        )
    }
    
    func didDisconnect(from peerID: MCPeerID) {
        
        connectedPeerIDs.remove(peerID)
        stateContinuation.yield(
            .searching(connectedDeviceNameList: connectedPeerIDs.map(\.displayName))
        )
    }
    
    func next() -> (any CohabitantRegistrationStateBridge)? {
        
        provider.finishSearching()
        
        let firstPeerID = ([myPeerID] + connectedPeerIDs).sorted { $0.displayName < $1.displayName }.first
        if firstPeerID == myPeerID {
            
            return CohabitantRegistrationSenderState(
                myPeerID: myPeerID,
                cohabitantPeerIDs: connectedPeerIDs,
                provider: provider,
                stateContinuation: stateContinuation
            )
        }
        else {
            
            let disconnectTargets = connectedPeerIDs.filter { $0 != firstPeerID }
            if !disconnectTargets.isEmpty {
                
                provider.disconnect(to: .init(disconnectTargets))
            }
            return CohabitantRegistrationReceiverState(
                provider: provider,
                stateContinuation: stateContinuation
            )
        }
    }
    
    func sendMessage<Message>(_ message: Message) throws where Message: Encodable {
        
        preconditionFailure("Unexpected call(message: \(message))")
    }
}
