//
//  CohabitantRegistrationDataStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/12.
//

import MultipeerConnectivity
import SwiftUI

@MainActor
@Observable
final class CohabitantRegistrationDataStore {
    
    var cohabitantPeerIDs: [String] = []

    @ObservationIgnored
    private var stateBridge: (any CohabitantRegistrationStateBridge)?
    
    private let continuation: AsyncStream<CohabitantRegistrationState>.Continuation
    private let stateStream: AsyncStream<CohabitantRegistrationState>
    
    init(provider: some P2PServiceProvider, myPeerID: MCPeerID) {
        
        let (stateStream, continuation) = AsyncStream<CohabitantRegistrationState>.makeStream()
        self.stateStream = stateStream
        self.continuation = continuation
        stateBridge = CohabitantRegistrationScanningState(
            myPeerID: myPeerID,
            provider: provider,
            stateContinuation: continuation
        )
    }
    
    func startLoading() async {
        
        continuation.yield(.searching)
        
        for await state in stateStream {
            // イベントディスパッチ
            switch state {
                
            case .initial: return
                    
            case .searching: break
                
            case .registering:
                stateBridge = stateBridge?.next()
                
            case .registered:
                stateBridge = nil
                
            case .error:
                stateBridge = nil
            }
            
            stateBridge?.didEnter()
        }
    }
    
    func removeResources() {
        
        continuation.finish()
    }
    
    func register() async {
        
    }
}
