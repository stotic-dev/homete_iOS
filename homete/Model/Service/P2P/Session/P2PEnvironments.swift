//
//  P2PEnvironments.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import MultipeerConnectivity
import SwiftUI

extension EnvironmentValues {
    
    @Entry var myPeerID: MCPeerID?
    @Entry var p2pSession: MCSession?
    @Entry var connectedPeers: Set<MCPeerID> = []
    @Entry var p2pSessionReceiveDataStream: AsyncStream<P2PSessionReceiveData> = .init { nil }
}
