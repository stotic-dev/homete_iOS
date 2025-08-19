//
//  CohabitantRegistrationScanningSequence.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

final class CohabitantRegistrationScanningSequence: CohabitantRegistrationP2PSequence, P2PServiceDelegate {
    
    let myPeerID: MCPeerID
    private(set) var connectedPeerIDs: Set<MCPeerID> = []
    private(set) var provider: any P2PServiceProvider
    let stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    
    private var registrablePeerIDs: Set<MCPeerID> = []
    
    init(
        myPeerID: MCPeerID,
        provider: any P2PServiceProvider,
        stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    ) {
        
        self.myPeerID = myPeerID
        self.provider = provider
        self.stateContinuation = stateContinuation
        self.provider.delegate = self
        
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
    
    func next() -> (any CohabitantRegistrationP2PSequence)? {
        
        provider.finishSearching()
        
        guard let firstPeerID = ([myPeerID] + connectedPeerIDs)
            .sorted(by: { $0.displayName < $1.displayName }).first else {
            
            return nil
        }
        if firstPeerID == myPeerID {
            
            return CohabitantRegistrationSenderSequence(
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
            return CohabitantRegistrationReceiverSequence(
                connectedPeerId: firstPeerID,
                provider: provider,
                stateContinuation: stateContinuation
            )
        }
    }
    
    func sendMessage<Message>(_ message: Message) throws where Message: Encodable {
        
        print("\(#file) \(#function)")
        let encodedData = try JSONEncoder().encode(message)
        provider.send(encodedData, to: .init(connectedPeerIDs))
    }
    
    func didReceiveData(_ data: Data, from peerID: MCPeerID) {
        
        print("\(#file) \(#function)")
        let decoder = JSONDecoder()

        if let message = try? decoder.decode(CohabitantRegistrationConfirmMessage.self, from: data) {
            
            print("received CohabitantRegistrationConfirmMessage: \(message)")
            
            if message.response == .ok {
                
                registrablePeerIDs.insert(peerID)
                stateContinuation.yield(.receivedRegistrationRequest(isAllConfirmation: registrablePeerIDs == connectedPeerIDs))
            }
            else {
                
                stateContinuation.yield(.searching(connectedDeviceNameList: connectedPeerIDs.map(\.displayName)))
            }
        }
    }
}
