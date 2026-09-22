//
//  CohabitantRegistrationProcessingFollowerView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/28.
//

import HometeDomain
import HometeUI
import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationProcessingFollower: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.p2pSessionProxy) var p2pSessionProxy
    @Environment(\.p2pSessionReceiveData) var receiveData
    @Environment(\.loginContext.account.id) var accountId
    @Environment(\.onCompleteCohabitantRegistration) var onCompleteCohabitantRegistration

    /// 自分のアカウントへの保存まで済んだ同居人ID
    @State var registeredCohabitantId: String?
    @State var confirmedRolePeers: Set<MCPeerID> = []
    @State var leadPeer: MCPeerID?
    /// 同居人IDの保存に失敗した時のアラート
    @State var isPresentingFailedRegistrationAlert = false

    @Binding var registrationState: CohabitantRegistrationState

    var body: some View {
        CohabitantRegistrationProcessingView(
            confirmedRolePeers: $confirmedRolePeers,
            registrationState: $registrationState,
            role: .follower(accountId: accountId)
        )
        .alert(
            "登録に失敗しました",
            isPresented: $isPresentingFailedRegistrationAlert
        ) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("お手数ですが、通信状況をご確認の上、再度接続からお試しください。")
        }
        .onChange(of: receiveData) { _, newValue in
            guard let newValue else { return }
            let data = CohabitantRegistrationMessage(newValue.body)
            dispatchReceivedMessage(data, sender: newValue.sender)
        }
    }

}

private extension CohabitantRegistrationProcessingFollower {

    func dispatchReceivedMessage(_ data: CohabitantRegistrationMessage, sender: MCPeerID) {
        // 登録前メッセージ受信時は、役割を確認し自身の役割に応じた処理を行う
        if data.memberRole?.isLeader ?? false {
            print("received preRegistration(lead) from: \(sender.displayName)")
            onFindLeader(sender)
        }
        // 同居人IDの共有メッセージ受信時は、
        // 同居人IDを自分のアカウントに保存してから登録完了通知をリードデバイスに通知
        else if let cohabitantId = data.cohabitantId {
            print("received shareCohabitantId from: \(sender.displayName)")
            onReceiveCohabitantId(cohabitantId, from: sender)
        }
        // 登録完了通知を受信したら、状態を登録完了にする
        else if data.isComplete ?? false {
            print("received complete from: \(sender.displayName)")
            registrationState = .completed
        }
    }

    func onFindLeader(_ peerID: MCPeerID) {
        leadPeer = peerID
        confirmedRolePeers.insert(peerID)

        // すでに同居人IDの保存まで済んでいたら、完了メッセージを送信する
        if registeredCohabitantId != nil {
            sendCompleteMessageIfNeeded()
        }
    }

    func onReceiveCohabitantId(_ cohabitantId: String, from sender: MCPeerID) {
        // 同居人IDを共有してくるのはリードデバイスだけなので、送信元をリードデバイスとして扱う。
        // リードデバイスは全員の役割が揃った時点で役割の通知をやめるため、こちらの役割通知が
        // 相手の最初の通知より先に届くと、役割の通知だけが一度も来ないまま同居人IDが届くことがある
        if leadPeer == nil {
            onFindLeader(sender)
        }
        Task {
            do {
                // 保存が済む前に完了を伝えると、保存に失敗しても全デバイスが完了扱いになるため、
                // 成功を待ってから完了メッセージを送る
                try await onCompleteCohabitantRegistration(cohabitantId)
                registeredCohabitantId = cohabitantId
                sendCompleteMessageIfNeeded()
            } catch {
                isPresentingFailedRegistrationAlert = true
            }
        }
    }

    func sendCompleteMessageIfNeeded() {
        guard let leadPeer else {
            print("skip sending complete. lead peer is unknown")
            return
        }

        let message = CohabitantRegistrationMessage(type: .complete)
        // 送信失敗時は切断され、connectedPeersの変化をProcessingViewが接続エラーとして拾う
        try? p2pSessionProxy?.send(
            message.encodedData(),
            to: [leadPeer]
        )
        print("sent complete to: \(leadPeer.displayName)")
    }

}
