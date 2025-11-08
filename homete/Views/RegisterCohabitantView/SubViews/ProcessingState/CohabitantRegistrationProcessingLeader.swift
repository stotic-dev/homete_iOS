//
//  CohabitantRegistrationProcessingLeaderView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/28.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationProcessingLeader: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.appDependencies.cohabitantClient) var cohabitantClient
    @Environment(\.p2pSessionProxy) var p2pSessionProxy
    @Environment(\.myPeerID) var myPeerID
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.p2pSessionReceiveData) var receiveData
    @Environment(AccountStore.self) var accountStore
    
    @AppStorage(key: .cohabitantId) var cohabitantId = ""
    
    // 登録処理の役割の通知が済んでいるデバイスリスト
    @State var confirmedRolePeers: Set<MCPeerID> = []
    @State var cohabitantsAccountId: Set<String> = []
    // 登録完了したデバイスリスト
    @State var completedRegistrationPeers: Set<MCPeerID> = []
    // 同居人レコードの登録に失敗した時のアラート
    @State var isPresentingFailedRegistrationIdAlert = false
    
    @Binding var registrationState: CohabitantRegistrationState
    
    var body: some View {
        CohabitantRegistrationProcessingView(
            confirmedRolePeers: $confirmedRolePeers,
            registrationState: $registrationState,
            role: .lead
        )
        .alert(
            "登録に失敗しました",
            isPresented: $isPresentingFailedRegistrationIdAlert
        ) {
            Button("OK") {
                cohabitantId = ""
                dismiss()
            }
        } message: {
            Text("お手数ですが、通信状況をご確認の上、再度接続からお試しください。")
        }
        .onChange(of: confirmedRolePeers) {
            // 全員の役割が分かった時点で、同居人のレコードを作成する
            guard confirmedRolePeers == connectedPeers else { return }
            onReadyRegistration()
        }
        .onChange(of: completedRegistrationPeers) {
            // 他のデバイス全てから登録完了通知が来たら、他デバイスに登録通知を送って登録完了にする
            guard completedRegistrationPeers == connectedPeers else { return }
            onCompletedRegistration()
        }
        .onChange(of: receiveData) { _, newValue in
            guard let newValue else { return }
            let data = CohabitantRegistrationMessage(newValue.body)
            dispatchReceivedMessage(data, newValue.sender)
        }
    }
}

private extension CohabitantRegistrationProcessingLeader {
    
    func dispatchReceivedMessage(_ data: CohabitantRegistrationMessage, _ sender: MCPeerID) {
        
        // フォロワーからのメッセージであれば、
        // 登録時に使用するアカウントIDをオンメモリに保持しておく
        if let accountId = data.memberRole?.accountId {
            
            cohabitantsAccountId.insert(accountId)
            confirmedRolePeers.insert(sender)
        }
        // フォロワーからの同居人登録完了メッセージ受信時は、保持している完了したメンバーに加える
        else if data.isComplete ?? false {
            
            completedRegistrationPeers.insert(sender)
        }
    }
    
    func onReadyRegistration() {
        
        if cohabitantId.isEmpty {
            
            cohabitantId = UUID().uuidString
        }
                
        Task {
            
            do {
                
                try await cohabitantClient.register(
                    .init(
                        id: cohabitantId,
                        members: [accountStore.account.id] + .init(cohabitantsAccountId)
                    )
                )
                
                // 同居人IDをメンバーに連携する
                let message = CohabitantRegistrationMessage(type: .shareCohabitantId(id: cohabitantId))
                p2pSessionProxy?.send(
                    message.encodedData(),
                    to: connectedPeers
                )
            }
            catch {
                
                // エラーアラートを表示
                isPresentingFailedRegistrationIdAlert = true
            }
        }
    }
    
    func onCompletedRegistration() {
        
        let message = CohabitantRegistrationMessage(type: .complete)
        p2pSessionProxy?.send(
            message.encodedData(),
            to: connectedPeers
        )
        registrationState = .completed
    }
}
