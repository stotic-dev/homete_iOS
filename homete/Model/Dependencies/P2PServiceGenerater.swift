//
//  P2PServiceGenerater.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/12.
//

import MultipeerConnectivity

struct P2PServiceGenerater {
    
    let service: @Sendable (MCPeerID, P2PServiceType) -> any P2PServiceProvider
}

extension P2PServiceGenerater: DependencyClient {
    
    static let liveValue: P2PServiceGenerater = .init { peerID, serviceType in
        
        return P2PService(peerID: peerID, serviceType: serviceType.rawValue)
    }
    
    static let previewValue: P2PServiceGenerater = .init { _, _ in
        
        return P2PServiceProviderMock()
    }
}
