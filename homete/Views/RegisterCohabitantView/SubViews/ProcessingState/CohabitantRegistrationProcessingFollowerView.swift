//
//  CohabitantRegistrationProcessingFollowerView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/28.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationProcessingFollower: View {
    
    @Environment(\.p2pSessionProxy) var p2pSessionProxy
    @Environment(\.p2pSessionReceiveDataStream) var receiveDataStream
    @Environment(AccountStore.self) var accountStore
    
    @AppStorage(key: .cohabitantId) var cohabitantId = ""
    
    @State var confirmedRolePeers: Set<MCPeerID> = []
    @State var leadPeer: MCPeerID?
    
    @Binding var registrationState: CohabitantRegistrationState
    
    var body: some View {
        CohabitantRegistrationProcessingView(
            confirmedRolePeers: $confirmedRolePeers,
            registrationState: $registrationState,
            role: .follower(accountId: accountStore.account.id)
        )
        .task {
            for await receiveData in receiveDataStream {
                let data = CohabitantRegistrationMessage(receiveData.body)
                dispatchReceivedMessage(data, sender: receiveData.sender)
            }
        }
    }
}

private extension CohabitantRegistrationProcessingFollower {
    
    func dispatchReceivedMessage(_ data: CohabitantRegistrationMessage, sender: MCPeerID) {
        
        // 登録前メッセージ受信時は、役割を確認し自身の役割に応じた処理を行う
        if data.memberRole?.isLeader ?? false {
            
            onFindLeader(sender)
        }
        // 同居人IDの共有メッセージ受信時は、
        // 同居人IDをローカルに保存して登録完了通知をリードデバイスに通知
        else if let cohabitantId = data.cohabitantId {
            
            onReceiveCohabitantId(cohabitantId)
        }
        // 登録完了通知を受信したら、状態を登録完了にする
        else if data.isComplete ?? false {
            
            registrationState = .completed
        }
    }
    
    func onFindLeader(_ peerID: MCPeerID) {
        
        leadPeer = peerID
        confirmedRolePeers.insert(peerID)
    }
    
    func onReceiveCohabitantId(_ cohabitantId: String) {
        
        guard let leadPeer else {
            
            preconditionFailure("Not found lead peer.")
        }
        
        self.cohabitantId = cohabitantId
        let message = CohabitantRegistrationMessage(type: .complete)
        p2pSessionProxy?.send(
            message.encodedData(),
            to: [leadPeer]
        )
    }
}
