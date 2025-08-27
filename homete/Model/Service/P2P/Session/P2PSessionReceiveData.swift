//
//  P2PSessionReceiveData.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/27.
//

import MultipeerConnectivity

@MainActor
struct P2PSessionReceiveData {
    
    let sender: MCPeerID
    let body: Data
}
