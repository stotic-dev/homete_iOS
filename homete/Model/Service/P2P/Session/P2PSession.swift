//
//  P2PSession.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//


import MultipeerConnectivity
import SwiftUI

struct P2PSession<Content: View>: View {
    
    @State var session: MCSession
    @State var myPeerID: MCPeerID
    var connectedPeersStore = P2PConnectedPeersStore()
    
    let content: () -> Content
    
    init(myPeerID: MCPeerID, @ViewBuilder content: @escaping () -> Content) {
        self.session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        self.myPeerID = myPeerID
        self.content = content
    }
    
    var body: some View {
        content()
            .environment(\.myPeerID, myPeerID)
            .environment(\.p2pSession, session)
            .environment(connectedPeersStore)
    }
}

extension EnvironmentValues {
    
    @Entry var myPeerID: MCPeerID?
    @Entry var p2pSession: MCSession?
}
