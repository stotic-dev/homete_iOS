//
//  P2PSession.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//

import MultipeerConnectivity
import SwiftUI

struct P2PSession<Content: View>: View {
        
    @AppStorage(key: .archivedPeerIDDataKey) var archivedPeerIDDataKey
    
    @State var session: MCSession?
    @State var myPeerID: MCPeerID?
    @State var connectedPeers: Set<MCPeerID> = []
    @State var sessionDelegate = P2PSessionDelegate()
    @State var receiveDataContinuation: AsyncStream<P2PSessionReceiveData>.Continuation
    @State var receiveDataStream: AsyncStream<P2PSessionReceiveData>
    
    let content: (MCSession?) -> Content
    let displayName: String
    
    init(displayName: String, @ViewBuilder content: @escaping (MCSession?) -> Content) {
        
        self.content = content
        self.displayName = displayName
        let (stream, continuation) = AsyncStream<P2PSessionReceiveData>.makeStream()
        receiveDataStream = stream
        receiveDataContinuation = continuation
    }
    
    var body: some View {
        content(session)
            .environment(\.myPeerID, myPeerID)
            .environment(\.connectedPeers, connectedPeers)
            .environment(\.p2pSessionReceiveDataStream, receiveDataStream)
            .environment(\.p2pSessionProxy, .init(session: session))
            .task {
                await onAppear()
                
                for await event in sessionDelegate.eventStream {
                    
                    switch event {
                    case .connected(let peerID):
                        connectedPeers.insert(peerID)
                        
                    case .disconnected(let peerID):
                        connectedPeers.remove(peerID)
                        
                    case .received(let data, let sender):
                        receiveDataContinuation.yield(.init(sender: sender, body: data))
                    }
                    
                    print("\(#file) event: \(event), connectedPeers: \(connectedPeers)")
                }
            }
            .onDisappear {
                receiveDataContinuation.finish()
                sessionDelegate.finish()
            }
    }
}

private extension P2PSession {
    
    func onAppear() async {
        
        let myPeerData = MyPeerData.make(
            archivedData: archivedPeerIDDataKey,
            displayName: displayName
        )
        self.session = MCSession(
            peer: myPeerData.id,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        myPeerID = myPeerData.id
        archivedPeerIDDataKey = myPeerData.archivedData
        
        session?.delegate = sessionDelegate
    }
}
