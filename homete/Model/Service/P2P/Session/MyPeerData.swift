//
//  MyPeerData.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import MultipeerConnectivity

struct MyPeerData: Equatable {
    
    let id: MCPeerID
    let archivedData: Data?
    
    static func make(archivedData: Data?, displayName: String) -> Self {
        
        do {
            
            if let myPeerIDArchivedData = archivedData,
               let myPeerID = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: MCPeerID.self,
                from: myPeerIDArchivedData
               ) {
                
                if myPeerID.displayName.hasPrefix(displayName) {
                    
                    return .init(id: myPeerID, archivedData: myPeerIDArchivedData)
                }
                else {
                    
                    let myPeerID = MCPeerID(displayName: "\(displayName)_\(UUID().uuidString)")
                    let archivedData = try NSKeyedArchiver.archivedData(
                        withRootObject: myPeerID,
                        requiringSecureCoding: true
                    )
                    
                    return .init(id: myPeerID, archivedData: archivedData)
                }
            }
            else {
                
                let myPeerID = MCPeerID(displayName: "\(displayName)_\(UUID().uuidString)")
                let archivedData = try NSKeyedArchiver.archivedData(
                    withRootObject: myPeerID,
                    requiringSecureCoding: true
                )
                return .init(id: myPeerID, archivedData: archivedData)
            }
        }
        catch {
            
            let myPeerID = MCPeerID(displayName: "\(displayName)_\(UUID().uuidString)")
            let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: myPeerID, requiringSecureCoding: true)
            return .init(id: myPeerID, archivedData: archivedData)
        }
    }
}
