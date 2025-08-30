//
//  CohabitantRegistrationPeersListView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationPeersListView: View {
    
    @Environment(\.p2pSession) var p2pSession
    @Environment(\.connectedPeers) var connectedPeers
    
    @State var isPresentingConfirmReadyRegistrationAlert = false
    @Binding var isConfirmedReadyRegistration: Bool
    
    var body: some View {
        ZStack {
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
            .padding(.horizontal, DesignSystem.Space.space16)
            if isConfirmedReadyRegistration {
                LoadingIndicator()
                    .ignoresSafeArea()
            }
        }
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
}

private extension CohabitantRegistrationPeersListView {
    
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
}

#Preview("デバイス検知済みケース") {
    @Previewable @State var isConfirmedReadyRegistration = false
    CohabitantRegistrationPeersListView(
        isConfirmedReadyRegistration: $isConfirmedReadyRegistration
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("確認アラート表示中のケース") {
    @Previewable @State var isConfirmedReadyRegistration = false
    CohabitantRegistrationPeersListView(
        isPresentingConfirmReadyRegistrationAlert: true,
        isConfirmedReadyRegistration: $isConfirmedReadyRegistration
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("登録開始待ちケース") {
    @Previewable @State var isConfirmedReadyRegistration = true
    CohabitantRegistrationPeersListView(
        isConfirmedReadyRegistration: $isConfirmedReadyRegistration
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}
