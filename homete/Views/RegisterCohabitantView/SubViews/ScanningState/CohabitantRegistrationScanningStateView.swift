//
//  CohabitantRegistrationSearchingStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationScanningStateView: View {
    
    @Environment(\.p2pSession) var p2pSession
    @Environment(\.myPeerID) var myPeerID
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.p2pSessionReceiveDataStream) var receiveDataStream
    
    @State var isConfirmedReadyRegistration = false
    @State var confirmedReadyRegistrationPeers: Set<MCPeerID> = []
    @Binding var registrationState: CohabitantRegistrationViewState
    
    let scannerController: any P2PScannerClient
    
    var body: some View {
        ZStack {
            if connectedPeers.isEmpty {
                CohabitantRegistrationInitialStateView()
                    .transition(.opacity)
            }
            else {
                CohabitantRegistrationPeersListView(
                    isConfirmedReadyRegistration: $isConfirmedReadyRegistration
                )
                .transition(.opacity)
            }
        }
        .animation(.spring, value: connectedPeers.isEmpty)
        .onAppear {
            scannerController.startScan()
        }
        .onDisappear {
            scannerController.finishScan()
        }
        .onChange(of: isConfirmedReadyRegistration) {
            transitionToProcessingStateIfNeeded()
        }
        .onChange(of: confirmedReadyRegistrationPeers) {
            transitionToProcessingStateIfNeeded()
        }
        .task {
            
            for await receiveData in receiveDataStream {
                
                let data = CohabitantRegistrationMessage(receiveData.body)
                
                // 登録メンバー確定メッセージを受信し、確定であれば確定メンバーに含める
                if let isFixedMember = data.isFixedMember,
                   isFixedMember {
                    
                    confirmedReadyRegistrationPeers.insert(receiveData.sender)
                }
            }
        }
    }
}

private extension CohabitantRegistrationScanningStateView {
        
    // MARK: プレゼンテーション処理
    
    func transitionToProcessingStateIfNeeded() {
        
        // 自分が登録ボタンタップ済みで、かつ全てのメンバーが登録ボタンタップ済みの場合に、
        // 登録処理に移行する
        guard isConfirmedReadyRegistration,
              confirmedReadyRegistrationPeers == connectedPeers,
              let myPeerID = self.myPeerID else { return }
        let firstPeerID = ([myPeerID] + connectedPeers)
            .sorted { $0.displayName < $1.displayName }.first
        
        withAnimation {
            
            registrationState = .processing(isLead: firstPeerID == myPeerID)
        }
    }
}
