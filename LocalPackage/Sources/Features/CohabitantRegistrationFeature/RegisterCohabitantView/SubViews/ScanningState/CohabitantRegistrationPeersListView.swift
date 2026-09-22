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

    /// 登録開始を宣言済みのメンバー
    let confirmedPeers: Set<CohabitantRegistrationPeerID>
    /// 自分が登録開始を宣言済みかどうか
    /// - Note: 宣言済みの間は他のメンバーの宣言を待つ表示にし、ボタンは押せなくする
    let isConfirmed: Bool
    /// 表示中のメンバーで登録を開始するかどうかを確定した
    let onConfirmMembers: (_ isOK: Bool) -> Void

    var body: some View {
        VStack(spacing: .space16) {
            // メンバーが増えても、画面下部の「登録を開始する」を押せる高さを確保できるようスクロールさせる
            ScrollView {
                VStack(spacing: .space16) {
                    Text("デバイスの名前を確認してください")
                        .font(with: .headLineM)
                    ForEach(convertToPeerRows(connectedPeers), id: \.id) { row in
                        HStack(spacing: .space24) {
                            Image(systemName: "iphone")
                                .frame(width: 24, height: 24)
                                .padding(.space8)
                                .foregroundStyle(.onSurface)
                                .background(.primary3)
                                .cornerRadius(.radius8)
                            VStack(alignment: .leading, spacing: .space4) {
                                Text(row.displayName)
                                    .font(with: .body)
                                if row.isConfirmed {
                                    // 相手が先に宣言した場合、こちらの操作を止めずに待たれていることが分かるようにする
                                    Label("登録を開始して、あなたを待っています", systemImage: "checkmark.circle.fill")
                                        .font(with: .caption)
                                        .foregroundStyle(.primary1)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            if isConfirmed {
                Label("他のメンバーが登録を開始するのを待っています", systemImage: "hourglass")
                    .font(with: .caption)
                    .foregroundStyle(.onSubSurface)
            }
            Button {
                isPresentingConfirmReadyRegistrationAlert = true
            } label: {
                Text("登録を開始する")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
            .disabled(isConfirmed)
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

    struct PeerRow {

        /// displayNameにはUUIDが含まれるため、同名のメンバーがいても一意になる
        let id: String
        let displayName: String
        let isConfirmed: Bool

    }

    // MARK: プレゼンテーション処理

    func convertToPeerRows(_ peers: Set<MCPeerID>) -> [PeerRow] {
        peers.map { peer in
            let peerID = CohabitantRegistrationPeerID(displayName: peer.displayName)
            return PeerRow(
                id: peerID.displayName,
                displayName: peerID.userName,
                isConfirmed: confirmedPeers.contains(peerID)
            )
        }
    }

}

#Preview("CohabitantRegistrationPeersListView_デバイス検知済みケース") {
    CohabitantRegistrationPeersListView(
        confirmedPeers: [],
        isConfirmed: false,
        onConfirmMembers: { _ in }
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("CohabitantRegistrationPeersListView_確認アラート表示中のケース") {
    CohabitantRegistrationPeersListView(
        isPresentingConfirmReadyRegistrationAlert: true,
        confirmedPeers: [],
        isConfirmed: false,
        onConfirmMembers: { _ in }
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("CohabitantRegistrationPeersListView_相手が開始済みのケース") {
    CohabitantRegistrationPeersListView(
        confirmedPeers: [.init(displayName: "Test_UUID")],
        isConfirmed: false,
        onConfirmMembers: { _ in }
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}

#Preview("CohabitantRegistrationPeersListView_自分が開始済みで相手待ちのケース") {
    CohabitantRegistrationPeersListView(
        confirmedPeers: [],
        isConfirmed: true,
        onConfirmMembers: { _ in }
    )
    .environment(\.connectedPeers, [.init(displayName: "Test_UUID")])
}
