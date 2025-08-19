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
    var hasError = false
    var isConfirmedCohabitants = false
    var sharedCohabitantAccountIds: [String] = []
    var shouldShareAccountId = false
    
    private var isAllConfirmation = false
    
    @ObservationIgnored
    private var sequence: (any CohabitantRegistrationP2PSequence)?
    
    private let continuation: AsyncStream<CohabitantRegistrationSessionResponse>.Continuation
    private let stateStream: AsyncStream<CohabitantRegistrationSessionResponse>
    
    init(provider: some P2PServiceProvider, myPeerID: MCPeerID) {
        
        let (stateStream, continuation) = AsyncStream<CohabitantRegistrationSessionResponse>.makeStream()
        self.stateStream = stateStream
        self.continuation = continuation
        sequence = CohabitantRegistrationScanningSequence(
            myPeerID: myPeerID,
            provider: provider,
            stateContinuation: continuation
        )
    }
    
    func startLoading() async {
                
        for await response in stateStream {
            print("received response: \(response)")
            // イベントディスパッチ
            switch response {
            case .searching(let connectedDeviceNameList):
                state = .searching(connectedDeviceNameList: connectedDeviceNameList)
                                
            case .receivedRegistrationRequest(let isAllConfirmation):
                isConfirmedCohabitants = true
                self.isAllConfirmation = isAllConfirmation
                
                if state == .waitingForConfirmation,
                   isAllConfirmation {
                    
                    sequence = sequence?.next()
                    state = .registering(isLead: sequence is CohabitantRegistrationSenderSequence)
                }
                
            case .readyToShareAccountId:
                shouldShareAccountId = true
                
            case .receivedAccountId(let accounts):
                sharedCohabitantAccountIds = accounts
                
            case .receivedId(let cohabitantIdMessage):
                // TODO: 同居人IDの保存
                sendMessage(CohabitantRegistrationCompleteMessage(response: .ok))
                state = .completed
                
            case .completed:
                state = .completed
                
            case .error:
                hasError = true
            }
        }
    }
    
    func removeResources() {
        
        sequence = sequence?.next()
        continuation.finish()
    }
    
    func register() {
        
        if isAllConfirmation {
            
            sequence = sequence?.next()
            state = .registering(isLead: sequence is CohabitantRegistrationSenderSequence)
        }
        else {
            
            state = .waitingForConfirmation
            sendMessage(CohabitantRegistrationConfirmMessage(response: .ok))
        }
    }
    
    func shareAccount(id: String) {
        
        print("shareAccount: \(id)")
        let message = CohabitantAccountShareMessage(accountId: id)
        sendMessage(message)
    }
    
    func shareCohabitantInfo(cohabitantId: String) {
        
        print("shareCohabitantInfo cohabitantId: \(cohabitantId)")
        let message = CohabitantIdShareMessage(value: cohabitantId)
        sendMessage(message)
    }
}

private extension CohabitantRegistrationDataStore {
    
    func sendMessage<Message: Encodable>(_ message: Message) {
        
        do {
            
            try sequence?.sendMessage(message)
        }
        catch {
            
            print("failed to send message: \(error)")
            hasError = true
        }
    }
}
