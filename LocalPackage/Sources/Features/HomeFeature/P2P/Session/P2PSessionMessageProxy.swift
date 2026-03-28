//
//  P2PSessionMessageProxy.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import MultipeerConnectivity
import SwiftUI

struct P2PSessionMessageProxy {
    
    private let session: MCSession?
    
    init(session: MCSession?) {
        
        self.session = session
    }
    
    func send(_ message: Data, to peers: Set<MCPeerID>) {
        
        guard let session else {
            
            preconditionFailure("Not fount session instance.")
        }
        
        do {
            
            try session.send(message, toPeers: .init(peers), with: .reliable)
        }
        catch {
            
            print("Failed send message.")
            session.disconnect()
        }
    }
}

extension EnvironmentValues {
    
    @Entry var p2pSessionProxy: P2PSessionMessageProxy?
}
