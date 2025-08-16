//
//  P2PSessionState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/12.
//

import Foundation
import MultipeerConnectivity

enum P2PSessionState {
    
    case initial
    case scanning(P2PScanEvent)
    case connecting
    case connected(P2PSessionEvent)
    case disconnected
    case error(any Error)
}

enum P2PScanEvent: Equatable {
    
    case foundPeer(MCPeerID)
    case lostPeer(MCPeerID)
    case acceptInvitation
    case rejectInvitation(MCPeerID)
}

enum P2PSessionEvent: Equatable {
    
    case connect(MCPeerID)
    case receivedData(Data)
}
