//
//  CohabitantRegistrationDataStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/12.
//

import MultipeerConnectivity
import SwiftUI

enum CohabitantRegistrationState {
    
    /// 初期状態
    case initial
    /// 他ユーザーを探索中
    case searching
    /// 検知したユーザーを登録中
    case registering
    /// 同居人の登録完了
    case registered
    /// エラー発生
    case error
}

enum CohabitantRegistrationRole {
    
    case lead
    case receiver
}

struct CohabitantConnectionRoleMessage: Codable {
    
//    let connectedPeerIDList: Set<Data>
    let isLeadDevice: Bool
    
//    func decodePeerIDList() throws -> Set<MCPeerID> {
//        
//        let unarchivedObjectList = try connectedPeerIDList.compactMap {
//            
//            try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: $0)
//        }
//        return .init(unarchivedObjectList)
//    }
}

//extension CohabitantSearchingMessage {
    
//    init(peerIDList: Set<MCPeerID>, shouldStartRegistration: Bool) throws {
//        
//        let archivedDataList = try peerIDList.map {
//            
//            try NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true)
//        }
//        connectedPeerIDList = .init(archivedDataList)
//        self.shouldStartRegistration = shouldStartRegistration
//    }
//}

@MainActor
@Observable
final class CohabitantRegistrationDataStore {
    
    var cohabitantPeerIDs: Set<MCPeerID> = []
    var role: CohabitantRegistrationRole?

    @ObservationIgnored
    private var stateBridge: (any CohabitantRegistrationStateBridge)?
    
    private let provider: any P2PServiceProvider
    private let continuation: AsyncStream<CohabitantRegistrationState>.Continuation
    private let stateStream: AsyncStream<CohabitantRegistrationState>
    private let myPeerID: MCPeerID
    
    init(appDependencies: AppDependencies, displayName: String) {
        
        let (stateStream, continuation) = AsyncStream<CohabitantRegistrationState>.makeStream()
        self.stateStream = stateStream
        self.continuation = continuation
        let myPeerDisplayName = "\(displayName)_\(UUID().uuidString)"
        myPeerID = MCPeerID(displayName: myPeerDisplayName)
        self.provider = appDependencies.p2pServiceGenerator.service(
            myPeerID,
            .register
        )
        cohabitantPeerIDs.insert(myPeerID)
    }
    
    func startLoading() async {
        
        stateBridge = CohabitantRegistrationScanningState(
            myPeerID: myPeerID,
            cohabitantPeerIDs: [],
            provider: provider,
            stateContinuation: continuation
        )
    }
    
    func register() async {
                
        
    }
}
