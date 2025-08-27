//
//  CohabitantRegistrationSearchingStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationSearchingStateView: View {
    
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.p2pSession) var p2pSession
    @Binding var isConfirmedReadyRegistration: Bool
    @State var isPresentingConfirmReadyRegistrationAlert = false
    
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
        
        // TODO: 開始通知を送信する
        let data = CohabitantRegistrationConfirmMessage(
            type: .readyRegistration,
            response: .ok
        )
        guard let encodedData = try? JSONEncoder().encode(data) else { return }
        try? p2pSession?.send(
            encodedData,
            toPeers: .init(connectedPeers),
            with: .reliable
        )
    }
}

#Preview("デバイス未検知ケース") {
    @Previewable @State var isConfirmedReadyRegistration = false
    CohabitantRegistrationSearchingStateView(
        isConfirmedReadyRegistration: $isConfirmedReadyRegistration,
        scannerController: P2PScannerClientMock()
    )
}

#Preview("デバイス検知済みケース") {
    @Previewable @State var isConfirmedReadyRegistration = false
    CohabitantRegistrationSearchingStateView(
        isConfirmedReadyRegistration: $isConfirmedReadyRegistration,
        scannerController: P2PScannerClientMock()
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("確認アラート表示中のケース") {
    @Previewable @State var isConfirmedReadyRegistration = false
    CohabitantRegistrationSearchingStateView(
        isConfirmedReadyRegistration: $isConfirmedReadyRegistration,
        isPresentingConfirmReadyRegistrationAlert: true,
        scannerController: P2PScannerClientMock()
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("登録開始待ちケース") {
    @Previewable @State var isConfirmedReadyRegistration = true
    CohabitantRegistrationSearchingStateView(
        isConfirmedReadyRegistration: $isConfirmedReadyRegistration,
        scannerController: P2PScannerClientMock()
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}
