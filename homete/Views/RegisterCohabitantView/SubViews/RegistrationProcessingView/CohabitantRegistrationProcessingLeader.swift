//
//  CohabitantRegistrationProcessingLeaderView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/28.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationProcessingLeader: View {
    
    @Environment(\.appDependencies.cohabitantClient) var cohabitantClient
    @Environment(\.appDependencies.appStorage) var appStorage
    @Environment(\.p2pSession) var p2pSession
    @Environment(\.myPeerID) var myPeerID
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.p2pSessionReceiveDataStream) var receiveDataStream
    @Environment(AccountStore.self) var accountStore
    
    // 登録処理の役割の通知が済んでいるデバイスリスト
    @State var confirmedRolePeers: Set<MCPeerID> = []
    @State var cohabitantsAccountId: Set<String> = []
    // 登録完了したデバイスリスト
    @State var completedRegistrationPeers: Set<MCPeerID> = []
    @Binding var registrationState: CohabitantRegistrationViewState
    
    var body: some View {
        CohabitantRegistrationProcessingView(confirmedRolePeers: $confirmedRolePeers)
            .onChange(of: confirmedRolePeers) {
                // 全員の役割が分かった時点で、自身がリードデバイスであれば、同居人のレコードを作成する
                guard confirmedRolePeers == connectedPeers else { return }
                
                let cohabitantId = UUID().uuidString
                
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
                        try p2pSession?.send(
                            message.encodedData(),
                            toPeers: .init(connectedPeers),
                            with: .reliable
                        )
                    }
                    catch {
                        // TODO: エラーハンドリング
                    }
                }
            }
            .onChange(of: completedRegistrationPeers) {
                // 他のデバイス全てから登録完了通知が来たら、他デバイスに登録通知を送って登録完了にする
                guard completedRegistrationPeers == connectedPeers else { return }
                
                // 登録完了通知を送信
                let message = CohabitantRegistrationMessage(type: .complete)
                do {
                    
                    try p2pSession?.send(
                        message.encodedData(),
                        toPeers: .init(connectedPeers),
                        with: .reliable
                    )
                }
                catch {
                    
                    // TODO: エラーハンドリング
                }
                registrationState = .completed
            }
            .task {
                for await receiveData in receiveDataStream {
                    
                    let data = CohabitantRegistrationMessage(receiveData.body)
                    
                    // フォロワーからのメッセージであれば、
                    // 登録時に使用するアカウントIDをオンメモリに保持しておく
                    if let accountId = data.memberRole?.accountId {
                        
                        cohabitantsAccountId.insert(accountId)
                        confirmedRolePeers.insert(receiveData.sender)
                    }
                    // フォロワーからの同居人登録完了メッセージ受信時は、保持している完了したメンバーに加える
                    else if data.isComplete ?? false {
                        
                        completedRegistrationPeers.insert(receiveData.sender)
                    }
                }
            }
    }
}
