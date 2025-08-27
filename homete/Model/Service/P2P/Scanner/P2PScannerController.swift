//
//  P2PScannerController.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//

import MultipeerConnectivity

@MainActor
enum P2PScanningEvent {
    
    /// 接続完了
    case connected(peerID: MCPeerID)
    /// 切断
    case disconnected(peerID: MCPeerID)
    /// エラー発生
    case error
}

final class P2PScannerController: NSObject {
    
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    let eventStream: AsyncStream<P2PScanningEvent>
    private var continuation: AsyncStream<P2PScanningEvent>.Continuation
    
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
        let (eventStream, continuation) = AsyncStream<P2PScanningEvent>.makeStream()
        self.eventStream = eventStream
        self.continuation = continuation
        
        super.init()
        
        session.delegate = self
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
        continuation.finish()
    }
}

extension P2PScannerController: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        print("did change session state: \(state)")
        if state == .connected {
            
            print("connected to: \(peerID.displayName)")
            continuation.yield(.connected(peerID: peerID))
        }
        else if state == .notConnected {
            
            print("disconnected to: \(peerID.displayName)")
            continuation.yield(.disconnected(peerID: peerID))
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        print("didReceive from: \(peerID.displayName), data: \(data)")
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
