//
//  CohabitantRegistrationRegisteringStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationRegisteringStateView: View {
    
    @Environment(\.appDependencies.cohabitantClient) var cohabitantClient
    @Environment(CohabitantRegistrationDataStore.self) var cohabitantRegistrationDataStore
    let myAccountId: String
    let isLeadDevice: Bool
    
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
        .onChange(of: cohabitantRegistrationDataStore.shouldShareAccountId) { _, newValue in
            guard newValue,
                  !isLeadDevice else { return }
            cohabitantRegistrationDataStore.shareAccount(id: myAccountId)
        }
        .onChange(of: cohabitantRegistrationDataStore.sharedCohabitantAccountIds) { _, cohabitantAccounts in
            guard !cohabitantAccounts.isEmpty else { return }
            let cohabitantId = UUID().uuidString
            
            Task {
                
                do {
                    
                    try await cohabitantClient.register(
                        .init(id: cohabitantId, members: [myAccountId] + cohabitantAccounts)
                    )
                    cohabitantRegistrationDataStore.shareCohabitantInfo(cohabitantId: cohabitantId)
                }
                catch {
                    // TODO: エラーハンドリング
                }
            }
        }
    }
}

#Preview {
    CohabitantRegistrationRegisteringStateView(myAccountId: "", isLeadDevice: false)
        .environment(
            CohabitantRegistrationDataStore(
                provider: P2PServiceProviderMock(),
                myPeerID: .init(displayName: "preview")
            )
        )
}
