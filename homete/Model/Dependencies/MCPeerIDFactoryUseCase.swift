//
//  P2PServiceGenerater.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/12.
//

import MultipeerConnectivity

enum MCPeerIDFactoryUseCase {
    
    static func make(
        appStore: AppStorage,
        displayName: String,
    ) async throws -> sending MCPeerID {
        
        if let myPeerIDArchivedData = await appStore.data(key: .archivedPeerIDDataKey),
           let myPeerID = try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: myPeerIDArchivedData) {
            
            if myPeerID.displayName.hasPrefix(displayName) {
                
                return myPeerID
            }
            else {
                
                let myPeerID = MCPeerID(displayName: "\(displayName)_\(UUID().uuidString)")
                let archivedData = try NSKeyedArchiver.archivedData(
                    withRootObject: myPeerID,
                    requiringSecureCoding: true
                )
                await appStore.setData(archivedData, key: .archivedPeerIDDataKey)
                return myPeerID
            }
        }
        else {
            
            let myPeerID = MCPeerID(displayName: "\(displayName)_\(UUID().uuidString)")
            let archivedData = try NSKeyedArchiver.archivedData(withRootObject: myPeerID, requiringSecureCoding: true)
            await appStore.setData(archivedData, key: .archivedPeerIDDataKey)
            return myPeerID
        }
    }
}
