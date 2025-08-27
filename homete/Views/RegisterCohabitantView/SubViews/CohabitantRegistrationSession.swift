//
//  CohabitantRegistrationSession.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/27.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationSession: View {
    
    @Environment(AccountStore.self) var accountStore
    @Environment(\.p2pSessionReceiveDataStream) var receiveDataStream
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.myPeerID) var myPeerID
    
    @State var viewState = CohabitantRegistrationViewState.scanning
    @State var confirmedReadyRegistrationPeers: Set<MCPeerID> = []
    @State var isConfirmedReadyRegistration = false
    
    var body: some View {
        ZStack {
            switch viewState {
            case .scanning:
                P2PScanner(serviceType: .register) {
                    CohabitantRegistrationSearchingStateView(
                        isConfirmedReadyRegistration: $isConfirmedReadyRegistration,
                        scannerController: $0
                    )
                }
                .transition(.slide)
            case .processing:
                CohabitantRegistrationProcessingView(
                    myAccountId: accountStore.account.id,
                    isLeadDevice: true
                )
                .transition(.slide)
            case .completed:
                CohabitantRegistrationCompleteView()
                    .transition(
                        .asymmetric(insertion: .slide, removal: .scale)
                    )
            }
        }
        .onChange(of: isConfirmedReadyRegistration) {
            transitionToProcessingStateIfNeeded()
        }
        .onChange(of: confirmedReadyRegistrationPeers) {
            transitionToProcessingStateIfNeeded()
        }
        .task {
            let decoder = JSONDecoder()
            
            for await receiveData in receiveDataStream {
                
                if let confirmMessage = try? decoder.decode(
                    CohabitantRegistrationConfirmMessage.self,
                    from: receiveData.body
                ) {
                    
                    // 登録開始確認のデータ受信時の処理
                    if confirmMessage.type == .readyRegistration,
                       confirmMessage.response == .ok {
                        
                        confirmedReadyRegistrationPeers.insert(receiveData.sender)
                    }
                }
            }
        }
    }
}

private extension CohabitantRegistrationSession {
    
    func transitionToProcessingStateIfNeeded() {
        
        // 自分が登録ボタンタップ済みで、かつ全てのメンバーが登録ボタンタップ済みの場合に、
        // 登録処理に移行する
        guard isConfirmedReadyRegistration,
              confirmedReadyRegistrationPeers == connectedPeers,
              let myPeerID = self.myPeerID else { return }
        let firstPeerID = ([myPeerID] + connectedPeers)
            .sorted { $0.displayName < $1.displayName }.first
        
        withAnimation {
            
            viewState = .processing(isLead: firstPeerID == myPeerID)
        }
    }
}
