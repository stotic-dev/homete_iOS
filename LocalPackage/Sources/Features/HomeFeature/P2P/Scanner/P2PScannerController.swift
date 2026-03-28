//
//  P2PScannerController.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//

import MultipeerConnectivity

final class P2PScannerController: NSObject {
    
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    
    init(
        session: MCSession,
        myPeerID: MCPeerID,
        serviceType: P2PServiceType
    ) {
        
        self.session = session
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: serviceType.rawValue
        )
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType.rawValue)
        
        super.init()
        
        advertiser.delegate = self
        browser.delegate = self
    }
}

extension P2PScannerController: P2PScannerClient {
    
    func startScan() {
        
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func finishScan() {
        
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
}

extension P2PScannerController: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        
        print("invitation from: \(peerID.displayName)")
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        
        print("advertising error: \(error)")
    }
}

extension P2PScannerController: MCNearbyServiceBrowserDelegate {
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        // swiftlint:disable:next discouraged_optional_collection
        withDiscoveryInfo info: [String: String]?
    ) {
        
        print("found device: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        print("lost device: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        
        print("browsing error: \(error)")
    }
}
