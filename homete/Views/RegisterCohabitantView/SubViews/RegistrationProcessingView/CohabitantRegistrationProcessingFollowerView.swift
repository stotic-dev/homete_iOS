//
//  CohabitantRegistrationProcessingFollowerView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/28.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationProcessingFollower: View {
    
    @Environment(\.appDependencies.appStorage) var appStorage
    @Environment(\.p2pSession) var p2pSession
    @Environment(\.p2pSessionReceiveDataStream) var receiveDataStream
    
    @State var confirmedRolePeers: Set<MCPeerID> = []
    @State var leadPeer: MCPeerID?
    
    @Binding var registrationState: CohabitantRegistrationViewState
    
    var body: some View {
        CohabitantRegistrationProcessingView(confirmedRolePeers: $confirmedRolePeers)
            .task {
                for await receiveData in receiveDataStream {
                    
                    let data = CohabitantRegistrationMessage(receiveData.body)
                    
                    // 登録前メッセージ受信時は、役割を確認し自身の役割に応じた処理を行う
                    if data.memberRole?.isLeader ?? false {
                        
                        leadPeer = receiveData.sender
                        confirmedRolePeers.insert(receiveData.sender)
                    }
                    // 同居人IDの共有メッセージ受信時は、
                    // 同居人IDをローカルに保存して登録完了通知をリードデバイスに通知
                    else if let cohabitantId = data.cohabitantId {
                        
                        // TODO: 同居人IDの永続化
                        // TODO: 登録処理完了通知を送信
                        
                    }
                    // 登録完了通知を受信したら、状態を登録完了にする
                    else if data.isComplete ?? false {
                        
                        registrationState = .completed
                    }
                }
            }
    }
}
