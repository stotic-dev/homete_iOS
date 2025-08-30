//
//  CohabitantRegistrationSearchingStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationSearchingStateView: View {
    
    @Environment(\.p2pSession) var p2pSession
    @Environment(\.myPeerID) var myPeerID
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.p2pSessionReceiveDataStream) var receiveDataStream
    
    @State var isConfirmedReadyRegistration = false
    @State var isPresentingConfirmReadyRegistrationAlert = false
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
                VStack(spacing: DesignSystem.Space.space16) {
                    Text("デバイスの名前を確認してください")
                        .font(with: .headLineM)
                    ForEach(convertToDisplayNameList(connectedPeers), id: \.self) { displayName in
                        HStack(spacing: DesignSystem.Space.space24) {
                            Image(systemName: "iphone")
                                .frame(width: 24, height: 24)
                                .padding(DesignSystem.Space.space8)
                                .foregroundStyle(.commonBlack)
                                .background(.primary3)
                                .cornerRadius(.radius8)
                            Text(displayName)
                                .font(with: .body)
                            Spacer()
                        }
                    }
                    Spacer()
                    Button {
                        isPresentingConfirmReadyRegistrationAlert = true
                    } label: {
                        Text("登録を開始する")
                            .frame(maxWidth: .infinity)
                    }
                    .subPrimaryButtonStyle()
                    Spacer()
                        .frame(height: DesignSystem.Space.space24)
                }
                .transition(.opacity)
                .padding(.horizontal, DesignSystem.Space.space16)
                .alert("表示されているメンバーで登録を開始しますか？", isPresented: $isPresentingConfirmReadyRegistrationAlert) {
                    Button {
                        // TODO: まだ登録しない
                    } label: {
                        Text("キャンセル")
                    }
                    Button {
                        tappedConfirmAlertAcceptButton()
                    } label: {
                        Text("開始する")
                    }
                }
            }
            if isConfirmedReadyRegistration {
                LoadingIndicator()
                    .ignoresSafeArea()
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

private extension CohabitantRegistrationSearchingStateView {
    
    // MARK: ドメイン処理
    
    func convertToDisplayNameList(_ peers: Set<MCPeerID>) -> [String] {
        
        return peers.compactMap {
            
            $0.displayName.components(separatedBy: "_").first
        }
    }
    
    // MARK: プレゼンテーション処理
    
    func tappedConfirmAlertAcceptButton() {
        
        isConfirmedReadyRegistration = true
        
        // メンバーが確定したことの通知を送信する
        let data = CohabitantRegistrationMessage(
            type: .fixedMember(isOK: true),
        )
        try? p2pSession?.send(
            data.encodedData(),
            toPeers: .init(connectedPeers),
            with: .reliable
        )
    }
    
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

#Preview("デバイス未検知ケース") {
    @Previewable @State var registrationState = CohabitantRegistrationViewState.scanning
    CohabitantRegistrationSearchingStateView(
        registrationState: $registrationState,
        scannerController: P2PScannerClientMock()
    )
}

#Preview("デバイス検知済みケース") {
    @Previewable @State var registrationState = CohabitantRegistrationViewState.scanning
    CohabitantRegistrationSearchingStateView(
        registrationState: $registrationState,
        scannerController: P2PScannerClientMock()
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("確認アラート表示中のケース") {
    @Previewable @State var registrationState = CohabitantRegistrationViewState.scanning
    CohabitantRegistrationSearchingStateView(
        isPresentingConfirmReadyRegistrationAlert: true,
        registrationState: $registrationState,
        scannerController: P2PScannerClientMock()
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("登録開始待ちケース") {
    @Previewable @State var registrationState = CohabitantRegistrationViewState.scanning
    CohabitantRegistrationSearchingStateView(
        isConfirmedReadyRegistration: true,
        registrationState: $registrationState,
        scannerController: P2PScannerClientMock()
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}
