//
//  P2PService.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import MultipeerConnectivity

final class P2PService: NSObject {
    
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    weak var delegate: (any P2PServiceDelegate)?
    
    init(peerID: MCPeerID, serviceType: P2PServiceType) {
        
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType.rawValue)
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType.rawValue)
        
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }
}

extension P2PService: P2PServiceProvider {
    
    func startSearching() {
        
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func finish() {
        
        session.disconnect()
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
    
    func send(_ data: Data, to peerID: [MCPeerID]) async {
        
        do {
            
            try session.send(data, toPeers: peerID, with: .reliable)
        }
        catch {
            
            delegate?.didReceiveError(error)
        }
    }
    
    func disconnect(to peerIDs: [MCPeerID]) {
        
        for peerID in peerIDs {
            
            session.cancelConnectPeer(peerID)
        }
    }
    
    func finishSearching() {
        
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
}

extension P2PService: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        if state == .connected {
            
            delegate?.didConnect(to: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        delegate?.didReceiveData(data, from: peerID)
    }
    
    // ...他のMCSessionDelegateメソッドは空実装...
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}
    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {}
}

extension P2PService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        
        print("invitation from: \(peerID.displayName)")
        let shouldAccept = delegate?.shouldAcceptInvitation(from: peerID) ?? false
        invitationHandler(shouldAccept, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        
        print("advertising error: \(error)")
        delegate?.didReceiveError(error)
    }
}

extension P2PService: MCNearbyServiceBrowserDelegate {
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        // swiftlint:disable:next discouraged_optional_collection
        withDiscoveryInfo info: [String: String]?
    ) {
        
        print("found device: \(peerID.displayName)")
        delegate?.didFoundDevice(peerID: peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        print("lost device: \(peerID.displayName)")
        delegate?.didLostDevice(peerID: peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        
        print("browsing error: \(error)")
        delegate?.didReceiveError(error)
    }
}
