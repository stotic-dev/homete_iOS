//
//  CohabitantRegistrationSenderState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

final class CohabitantRegistrationSenderSequence: CohabitantRegistrationP2PSequence {
    
    let myPeerID: MCPeerID
    private(set) var connectedPeerIDs: Set<MCPeerID>
    private(set) var provider: any P2PServiceProvider
    let stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    
    private var didShareAccountPeerList: Set<MCPeerID> = []
    private var didShareAccountIdList: [String] = []
    private var didConfirmPeerIDs: Set<MCPeerID> = []
    private var didCompletePeerIDs: Set<MCPeerID> = []
    
    private var timer: Timer?
    
    init(
        myPeerID: MCPeerID,
        cohabitantPeerIDs: Set<MCPeerID>,
        provider: any P2PServiceProvider,
        stateContinuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    ) {
        
        print("didEnter CohabitantRegistrationSenderSequence")
        self.myPeerID = myPeerID
        self.connectedPeerIDs = cohabitantPeerIDs
        self.provider = provider
        self.stateContinuation = stateContinuation
        self.provider.delegate = self
        
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            
//            try? self?.sendMessage(CohabitantRegistrationConfirmMessage(response: .ok))
        }
    }
    
    func next() -> (any CohabitantRegistrationP2PSequence)? {
        
        provider.finish()
        return nil
    }
    
    func didDisconnect(from peerID: MCPeerID) {
        
        stateContinuation.yield(.error)
        timer?.invalidate()
        timer = nil
    }
    
    func sendMessage<Message>(_ message: Message) throws where Message: Encodable {
        
        print("\(#file) \(#function)")
        let encodedData = try JSONEncoder().encode(message)
        provider.send(encodedData, to: .init(connectedPeerIDs))
    }
    
    func didReceiveData(_ data: Data, from peerID: MCPeerID) {
        
        print("\(#file) \(#function)")
        if let decodedData = try? JSONDecoder().decode(CohabitantAccountShareMessage.self, from: data) {
            
            didShareAccountIdList.append(decodedData.accountId)
            didShareAccountPeerList.insert(peerID)
            
            if didShareAccountPeerList == connectedPeerIDs {
                
                timer?.invalidate()
                timer = nil
                stateContinuation.yield(.receivedAccountId(didShareAccountIdList))
            }
        }
        else if let decodedData = try? JSONDecoder().decode(CohabitantRegistrationCompleteMessage.self, from: data),
           decodedData.response == .ok {
            
            didCompletePeerIDs.insert(peerID)
            if didCompletePeerIDs == connectedPeerIDs {
                
                try? sendMessage(CohabitantRegistrationCompleteMessage(response: .ok))
                stateContinuation.yield(.completed)
            }
        }
        else {
            
            preconditionFailure("did receive invalid message.")
        }
    }
}
