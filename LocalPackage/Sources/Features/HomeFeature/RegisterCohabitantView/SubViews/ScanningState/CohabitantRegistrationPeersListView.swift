//
//  CohabitantRegistrationPeersListView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import HometeDomain
import HometeResources
import HometeUI
import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationPeersListView: View {

    @Environment(\.connectedPeers) var connectedPeers

    @State var isPresentingConfirmReadyRegistrationAlert = false

    /// 表示中のメンバーで登録を開始するかどうかを確定した
    let onConfirmMembers: (_ isOK: Bool) -> Void

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
                onConfirmMembers(false)
            } label: {
                Text("キャンセル")
            }
            Button {
                onConfirmMembers(true)
            } label: {
                Text("開始する")
            }
        }
    }

}

private extension CohabitantRegistrationPeersListView {

    // MARK: プレゼンテーション処理

    func convertToDisplayNameList(_ peers: Set<MCPeerID>) -> [String] {
        peers.compactMap {
            $0.displayName.components(separatedBy: "_").first
        }
    }

}

#Preview("CohabitantRegistrationPeersListView_デバイス検知済みケース") {
    CohabitantRegistrationPeersListView(onConfirmMembers: { _ in })
        .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("CohabitantRegistrationPeersListView_確認アラート表示中のケース") {
    CohabitantRegistrationPeersListView(
        isPresentingConfirmReadyRegistrationAlert: true,
        onConfirmMembers: { _ in }
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}
