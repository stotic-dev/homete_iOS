//
//  CohabitantRegistrationPeersListView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationPeersListView: View {
    
    @Environment(\.p2pSessionProxy) var p2pSessionProxy
    @Environment(\.connectedPeers) var connectedPeers
    
    @State var isPresentingConfirmReadyRegistrationAlert = false
    @Binding var isConfirmedReadyRegistration: Bool
    
    var body: some View {
        VStack(spacing: .space16) {
            Text("デバイスの名前を確認してください")
                .font(with: .headLineM)
            ForEach(convertToDisplayNameList(connectedPeers), id: \.self) { displayName in
                HStack(spacing: .space24) {
                    Image(systemName: "iphone")
                        .frame(width: 24, height: 24)
                        .padding(.space8)
                        .foregroundStyle(.onSurface)
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
                .frame(height: .space24)
        }
        .padding(.horizontal, .space16)
        .alert("表示されているメンバーで登録を開始しますか？", isPresented: $isPresentingConfirmReadyRegistrationAlert) {
            Button {
                tappedConfirmAlertCancelButton()
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
    
    // MARK: プレゼンテーション処理
    
    func convertToDisplayNameList(_ peers: Set<MCPeerID>) -> [String] {
        
        return peers.compactMap {
            
            $0.displayName.components(separatedBy: "_").first
        }
    }
    
    func tappedConfirmAlertAcceptButton() {
        
        isConfirmedReadyRegistration = true
        
        // メンバーが確定したことの通知を送信する
        let data = CohabitantRegistrationMessage(
            type: .fixedMember(isOK: true),
        )
        p2pSessionProxy?.send(
            data.encodedData(),
            to: connectedPeers,
        )
    }
    
    func tappedConfirmAlertCancelButton() {
        
        // メンバーが確定していないことの通知を送信する
        let data = CohabitantRegistrationMessage(
            type: .fixedMember(isOK: false),
        )
        p2pSessionProxy?.send(
            data.encodedData(),
            to: connectedPeers,
        )
    }
}

#Preview("CohabitantRegistrationPeersListView_デバイス検知済みケース") {
    CohabitantRegistrationPeersListView(
        isConfirmedReadyRegistration: .constant(false)
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("CohabitantRegistrationPeersListView_確認アラート表示中のケース") {
    CohabitantRegistrationPeersListView(
        isPresentingConfirmReadyRegistrationAlert: true,
        isConfirmedReadyRegistration: .constant(false)
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}
