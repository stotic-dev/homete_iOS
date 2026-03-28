//
//  P2PSessionEvent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/27.
//

import MultipeerConnectivity

@MainActor
enum P2PSessionEvent {
    
    case connected(peerID: MCPeerID)
    case disconnected(peerID: MCPeerID)
    case received(data: Data, sender: MCPeerID)
}
