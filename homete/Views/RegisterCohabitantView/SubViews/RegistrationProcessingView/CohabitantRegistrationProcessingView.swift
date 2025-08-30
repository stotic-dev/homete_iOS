//
//  CohabitantRegistrationProcessingView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import Combine
import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationProcessingView: View {
    
    @Environment(\.p2pSession) var p2pSession
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(AccountStore.self) var accountStore
    
    // 登録処理の役割の通知が済んでいるデバイスリスト
    @Binding var confirmedRolePeers: Set<MCPeerID>
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: DesignSystem.Space.space16) {
                VStack(spacing: .zero) {
                    Text("登録はもうすぐ完了します！")
                    Text("共に家事を頑張るパートナーへ、エールを送り合いませんか？")
                }
                .font(with: .headLineM)
                Image(.cohabitantsHandShake)
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(.radius8)
                Text("しばらくお待ちください")
                    .font(with: .caption)
            }
            Spacer()
                .frame(height: DesignSystem.Space.space24)
            Indicator()
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Space.space16)
        .onReceive(timer) { _ in
            guard confirmedRolePeers != connectedPeers else { return }
            
            let message = CohabitantRegistrationMessage(
                type: .preRegistration(
                    role: .follower(accountId: accountStore.account.id)
                )
            )
            try? p2pSession?.send(
                message.encodedData(),
                toPeers: .init(connectedPeers),
                with: .reliable
            )
        }
    }
}

#Preview {
    @Previewable @State var confirmedRolePeers: Set<MCPeerID> = []
    CohabitantRegistrationProcessingView(confirmedRolePeers: $confirmedRolePeers)
}
