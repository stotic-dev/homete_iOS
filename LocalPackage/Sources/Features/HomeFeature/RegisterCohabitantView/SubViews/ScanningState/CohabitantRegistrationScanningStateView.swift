//
//  CohabitantRegistrationScanningStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import HometeDomain
import HometeUI
import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationScanningStateView: View {

    @Environment(\.appDependencies.cohabitantInvitationClient) var cohabitantInvitationClient
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.dismiss) var dismiss
    @Environment(\.myPeerID) var myPeerID
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.p2pSessionReceiveData) var receiveData
    @Environment(\.p2pSessionProxy) var p2pSessionProxy
    @LoadingState var loadingState

    @CommonError var errorContent
    @State var sharingInvitation: CohabitantInvitation?
    @State var isConfirmedReadyRegistration = false
    @State var isPresentingRejectRegistrationAlert = false
    /// メンバー確定の通知を送れなかった時のアラート
    /// - Note: 送信失敗時はセッションが切断されメンバー一覧が消えるため、一覧側ではなくここで出す
    @State var isPresentingFailedSendAlert = false
    @State var confirmedReadyRegistrationPeers = ConfirmedRegistrationPeers(peers: [])
    @Binding var registrationState: CohabitantRegistrationState

    let scannerController: any P2PScannerClient

    /// 招待リンクの共有アクション
    /// - Note: 招待リンクを利用できない環境では導線ごと出さないためnilにする
    var inviteAction: (() -> Void)? {
        guard CohabitantInvitationLink.isAvailable else { return nil }
        return { onTapInvite() }
    }

    var body: some View {
        ZStack {
            if connectedPeers.isEmpty {
                CohabitantRegistrationInitialStateView(onTapInvite: inviteAction)
                    .transition(.opacity)
                    .onAppear {
                        // 接続が全て切れたら宣言は無効になるため、自分・相手とも最初からやり直す
                        isConfirmedReadyRegistration = false
                        confirmedReadyRegistrationPeers = .init(peers: [])
                    }
            } else {
                CohabitantRegistrationPeersListView(
                    confirmedPeers: confirmedReadyRegistrationPeers.peers,
                    isConfirmed: isConfirmedReadyRegistration
                ) { isOK in
                    onConfirmMembers(isOK: isOK)
                }
                .transition(.opacity)
            }
        }
        .animation(.spring, value: connectedPeers.isEmpty)
        .fullScreenLoadingIndicator(loadingState)
        .sheet(item: $sharingInvitation) { invitation in
            if let url = invitation.url {
                ShareSheet(text: CohabitantInvitation.shareMessage, url: url) { completed in
                    onCompleteShareInvitation(completed)
                }
            }
        }
        .commonError(content: $errorContent)
        .alert(
            "通信中のメンバーがキャンセルしました",
            isPresented: $isPresentingRejectRegistrationAlert
        ) {
            Button("OK") { tappedRejectAlertButton() }
        }
        .alert(
            "接続エラー",
            isPresented: $isPresentingFailedSendAlert
        ) {
            Button("OK") {}
        } message: {
            Text("お手数ですが、再度デバイスを近づけて通信を行ってください")
        }
        .onAppear {
            scannerController.startScan()
        }
        .onDisappear {
            scannerController.finishScan()
        }
        .onChange(of: isConfirmedReadyRegistration) {
            transitionToProcessingStateIfNeeded()
        }
        .onChange(of: confirmedReadyRegistrationPeers) {
            transitionToProcessingStateIfNeeded()
        }
        .onChange(of: receiveData) { _, newValue in
            guard let newValue else { return }
            let data = CohabitantRegistrationMessage(newValue.body)
            dispatchReceivedMessage(data, newValue.sender)
        }
        .onChange(of: connectedPeers) { oldValue, newValue in
            if oldValue.isEmpty, !newValue.isEmpty {
                analyticsClient.log(.cohabitantRegistration(.peerFound))
            }
        }
    }

}

private extension CohabitantRegistrationScanningStateView {

    // MARK: プレゼンテーション処理

    func onTapInvite() {
        loadingState.isLoading = true
        Task {
            defer { loadingState.isLoading = false }
            do {
                // 発行時点ではグループは作られない。相手が参加した時点でサーバー側がグループを作り、
                // 自分のAccountが更新されるのを`AccountStore`の購読で受け取る
                sharingInvitation = try await cohabitantInvitationClient.issue()
                analyticsClient.log(.cohabitantInvitation(.issued(screen: .cohabitantRegistration, isSuccess: true)))
            } catch {
                errorContent = .init(error: error)
                analyticsClient.log(.cohabitantInvitation(.issued(screen: .cohabitantRegistration, isSuccess: false)))
            }
        }
    }

    /// 招待リンクの共有シートが閉じたときの処理
    ///
    /// 相手に共有できたら、この画面ですることは無くなるので登録画面ごと閉じる。
    /// 相手の参加は`AccountStore`の購読で受け取り、ホーム画面側が参加済みの表示に切り替わる。
    /// キャンセルした場合はP2P登録や再共有に進めるよう画面に留まる。
    func onCompleteShareInvitation(_ completed: Bool) {
        guard completed else { return }
        dismiss()
    }

    func onConfirmMembers(isOK: Bool) {
        // メンバーが確定したかどうかの通知を送信する
        let data = CohabitantRegistrationMessage(
            type: .fixedMember(isOK: isOK)
        )
        do {
            try p2pSessionProxy?.send(
                data.encodedData(),
                to: connectedPeers
            )
            print("sent fixedMember(isOK: \(isOK)) to: \(connectedPeers.map(\.displayName))")
            if isOK {
                isConfirmedReadyRegistration = true
            } else {
                // 相手側はキャンセルを受け取ると宣言をやり直すため、受け取っていた宣言も忘れる
                confirmedReadyRegistrationPeers = .init(peers: [])
            }
        } catch {
            isPresentingFailedSendAlert = true
        }
    }

    func dispatchReceivedMessage(_ data: CohabitantRegistrationMessage, _ sender: MCPeerID) {
        if let isFixedMember = data.isFixedMember {
            print("received fixedMember(isOK: \(isFixedMember)) from: \(sender.displayName)")
            if isFixedMember {
                // 登録メンバー確定メッセージを受信し、確定であれば確定メンバーに含める
                // （相手が待っていることはメンバー一覧側の表示で伝える）
                confirmedReadyRegistrationPeers.addPeer(sender)
            } else {
                // 登録メンバーが拒否した場合は、再度メンバーを選び直す
                confirmedReadyRegistrationPeers = .init(peers: [])
                isPresentingRejectRegistrationAlert = true
            }
        }
    }

    /// 自分が登録開始を宣言済みで、かつ接続中の全メンバーの宣言が届いている場合だけ登録処理に移行する
    /// - Note: 待っている間はスピナーを出さない。全画面のスピナーで覆うと、
    ///         相手の宣言だけが先に届いた側で「登録を開始する」を押せなくなり、お互いに待ち続けてしまう
    func transitionToProcessingStateIfNeeded() {
        guard isConfirmedReadyRegistration,
              let myPeerID,
              let isLeadPeer = confirmedReadyRegistrationPeers.isLeadPeer(
                  connectedPeers: connectedPeers,
                  myPeerID: myPeerID
              ) else {
            print(
                "waiting for peers. isConfirmed: \(isConfirmedReadyRegistration), "
                    + "confirmed: \(confirmedReadyRegistrationPeers.peers.map(\.displayName)), "
                    + "connected: \(connectedPeers.map(\.displayName))"
            )
            return
        }

        print("all peers confirmed. isLead: \(isLeadPeer)")
        registrationState = .processing(isLead: isLeadPeer)
    }

    func tappedRejectAlertButton() {
        isConfirmedReadyRegistration = false
    }

}
