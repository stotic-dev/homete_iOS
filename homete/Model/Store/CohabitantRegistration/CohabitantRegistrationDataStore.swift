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
    
    var state: CohabitantRegistrationState = .initial
    var cohabitantId: String?
    var hasError = false

    @ObservationIgnored
    private var stateBridge: (any CohabitantRegistrationStateBridge)?
    
    private let continuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    private let stateStream: AsyncStream<CohabitantRegistrationSessionResponse>
    
    init(provider: some P2PServiceProvider, myPeerID: MCPeerID) {
        
        let (stateStream, continuation) = AsyncStream<CohabitantRegistrationSessionResponse>.makeStream()
        self.stateStream = stateStream
        self.continuation = continuation
        stateBridge = CohabitantRegistrationScanningState(
            myPeerID: myPeerID,
            provider: provider,
            stateContinuation: continuation
        )
    }
    
    func startLoading() async {
        
        stateBridge?.didEnter()
        
        for await response in stateStream {
            // イベントディスパッチ
            switch response {
            case .searching(let connectedDeviceNameList):
                state = .searching(connectedDeviceNameList: connectedDeviceNameList)
                
            case .connected: break
                
            case .receivedId(let cohabitantIdMessage):
                cohabitantId = cohabitantIdMessage.value
                
            case .completed:
                state = .completed
                
            case .error:
                hasError = true
            }
        }
    }
    
    func removeResources() {
        
        continuation.finish()
    }
    
    func register() {
        
        state = .registering
        stateBridge = stateBridge?.next()
    }
    
    func shareCohabitantInfo(cohabitantId: String) {
        
        let message = CohabitantIdMessage(value: cohabitantId)
        
        do {
            
            try stateBridge?.sendMessage(message)
        }
        catch {
            
            print("failed to send message: \(error)")
            hasError = true
        }
    }
}
