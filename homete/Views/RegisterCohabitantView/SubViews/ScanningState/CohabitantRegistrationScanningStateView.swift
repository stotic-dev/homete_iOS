//
//  CohabitantRegistrationSearchingStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationScanningStateView: View {
    
    @Environment(\.myPeerID) var myPeerID
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.p2pSessionReceiveDataStream) var receiveDataStream
    
    @State var isConfirmedReadyRegistration = false
    @State var isPresentingRejectRegistrationAlert = false
    @State var confirmedReadyRegistrationPeers = ConfirmedRegistrationPeers(peers: [])
    @Binding var registrationState: CohabitantRegistrationState
    
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
        .alert(
            "通信中のメンバーがキャンセルしました",
            isPresented: $isPresentingRejectRegistrationAlert
        ) {
            Button("OK") { tappedRejectAlertButton() }
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
                dispatchReceivedMessage(data, receiveData.sender)
            }
        }
    }
}

private extension CohabitantRegistrationScanningStateView {
    
    // MARK: プレゼンテーション処理
    
    func dispatchReceivedMessage(_ data: CohabitantRegistrationMessage, _ sender: MCPeerID) {
        
        if let isFixedMember = data.isFixedMember {
            
            if isFixedMember {
                
                // 登録メンバー確定メッセージを受信し、確定であれば確定メンバーに含める
                confirmedReadyRegistrationPeers.addPeer(sender)
            }
            else {
                
                // 登録メンバーが拒否した場合は、再度メンバーを選び直す
                confirmedReadyRegistrationPeers = .init(peers: [])
                isPresentingRejectRegistrationAlert = true
            }
        }
    }
    
    func transitionToProcessingStateIfNeeded() {
        
        // 自分が登録ボタンタップ済みで、かつ全てのメンバーが登録ボタンタップ済みの場合に、
        // 登録処理に移行する
        guard isConfirmedReadyRegistration,
              let myPeerID = self.myPeerID,
        let isLeadPeer = confirmedReadyRegistrationPeers.isLeadPeer(
            connectedPeers: connectedPeers,
            myPeerID: myPeerID
        ) else { return }
        
        registrationState = .processing(isLead: isLeadPeer)
    }
    
    func tappedRejectAlertButton() {
        
        isConfirmedReadyRegistration = false
    }
}
