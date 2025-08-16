//
//  P2PService.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import MultipeerConnectivity

//extension MCPeerID {
//    
//    static func loadMyPeerID(_ achieved: Data?) -> MCPeerID {
//        
//        guard let achieved,
//              let peerID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: achieved) else {
//            
//            return .init(displayName: UUID().uuidString)
//        }
//        
//        return peerID
//    }
//}

protocol P2PServiceDelegate: AnyObject {
    
    /// 検索中にデバイスを発見したことを通知
    /// - Parameter peerID: 発見したデバイスの識別ID
    func didFoundDevice(peerID: MCPeerID)
    
    /// 検索中に発見していたデバイスを見失ったことを通知
    /// - Parameter peerID: 見失ったデバイスの識別ID
    func didLostDevice(peerID: MCPeerID)
    
    /// 発見したデバイスと接続するかどうかを判定する
    /// - Parameter peerID: 接続の招待をしたデバイスの識別ID
    /// - Returns: 接続するかどうか
    func shouldAcceptInvitation(from peerID: MCPeerID) -> Bool
    
    /// デバイスと接続したときの通知
    /// - Parameter peerID: 接続先の識別ID
    func didConnect(to peerID: MCPeerID)
    
    /// 接続していたデバイスと切断したことを通知
    /// - Parameter peerID: 切断したデバイスの識別ID
    func didDisconnect(from peerID: MCPeerID)
    
    /// データを受信したことを通知
    /// - Parameters:
    ///   - data: 受信したデータ
    ///   - peerID: 送信元のデバイスを識別するID
    func didReceiveData(_ data: Data, from peerID: MCPeerID)
    
    /// エラーが発生したことを通知
    func didReceiveError(_ error: any Error)
}

final class P2PService: NSObject {
    
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    weak var delegate: (any P2PServiceDelegate)?
    
    init(peerID: MCPeerID, serviceType: String) {
        
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        
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
        withDiscoveryInfo info: [String : String]?
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
