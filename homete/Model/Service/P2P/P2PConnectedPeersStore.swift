//
//  P2PConnectedPeersStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//

import MultipeerConnectivity
import SwiftUI

@Observable
final class P2PConnectedPeersStore {
    
    /// 接続中のデバイス
    var peers: Set<MCPeerID>
    /// 接続中にエラーが発生したかどうか
    var hasError: Bool
    
    init(
        peers: Set<MCPeerID> = [],
        hasError: Bool = false
    ) {
        
        self.peers = peers
        self.hasError = hasError
    }
}
