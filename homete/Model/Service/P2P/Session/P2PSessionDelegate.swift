//
//  P2PSessionDelegate.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/27.
//

import MultipeerConnectivity

final class P2PSessionDelegate: NSObject, MCSessionDelegate {
    
    let eventStream: AsyncStream<P2PSessionEvent>
    private let continuation: AsyncStream<P2PSessionEvent>.Continuation
    
    override init() {
        
        let (eventStream, continuation) = AsyncStream<P2PSessionEvent>.makeStream()
        self.eventStream = eventStream
        self.continuation = continuation
        
        super.init()
    }
    
    func finish() {
        
        continuation.finish()
    }
        
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
        continuation.yield(.received(data: data, sender: peerID))
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
