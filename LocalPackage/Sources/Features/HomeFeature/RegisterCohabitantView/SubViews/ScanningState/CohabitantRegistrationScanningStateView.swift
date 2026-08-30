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
    @Environment(AccountStore.self) var accountStore
    @Environment(\.myPeerID) var myPeerID
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.p2pSessionReceiveData) var receiveData
    @LoadingState var loadingState

    @CommonError var errorContent
    @State var sharingInvitation: CohabitantInvitation?
    @State var isConfirmedReadyRegistration = false
    @State var isPresentingRejectRegistrationAlert = false
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
                        isConfirmedReadyRegistration = false
                    }
            } else {
                CohabitantRegistrationPeersListView(
                    isConfirmedReadyRegistration: $isConfirmedReadyRegistration
                )
                .transition(.opacity)
            }
        }
        .animation(.spring, value: connectedPeers.isEmpty)
        .fullScreenLoadingIndicator(loadingState)
        .sheet(item: $sharingInvitation) { invitation in
            if let url = invitation.url {
                ShareSheet(text: Self.shareMessage, url: url)
            }
        }
        .commonError(content: $errorContent)
        .alert(
            "通信中のメンバーがキャンセルしました",
            isPresented: $isPresentingRejectRegistrationAlert
        ) {
            Button("OK") { tappedRejectAlertButton() }
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
    }

}

private extension CohabitantRegistrationScanningStateView {

    /// 招待リンクと一緒に送る文言
    static let shareMessage = "hometeで一緒に家事を管理しませんか？下のリンクから参加できます。"

    // MARK: プレゼンテーション処理

    func onTapInvite() {
        loadingState.isLoading = true
        Task {
            defer { loadingState.isLoading = false }
            do {
                let invitation = try await cohabitantInvitationClient.issue()
                // グループ未所属の場合はサーバ側で招待者ひとりのグループが作られるため、
                // オンメモリのアカウントにも反映してFirestoreの状態と揃える
                // （揃えないと、再起動するまでグループ未所属として振る舞ってしまう）
                accountStore.applyCohabitantId(invitation.cohabitantId)
                sharingInvitation = invitation
                analyticsClient.log(.cohabitantInvitation(.issued(isSuccess: true)))
            } catch {
                errorContent = .init(error: error)
                analyticsClient.log(.cohabitantInvitation(.issued(isSuccess: false)))
            }
        }
    }

    func dispatchReceivedMessage(_ data: CohabitantRegistrationMessage, _ sender: MCPeerID) {
        if let isFixedMember = data.isFixedMember {
            if isFixedMember {
                // 登録メンバー確定メッセージを受信し、確定であれば確定メンバーに含める
                confirmedReadyRegistrationPeers.addPeer(sender)
            } else {
                // 登録メンバーが拒否した場合は、再度メンバーを選び直す
                confirmedReadyRegistrationPeers = .init(peers: [])
                isPresentingRejectRegistrationAlert = true
            }
        }
    }

    func transitionToProcessingStateIfNeeded() {
        loadingState.isLoading = true

        // 自分が登録ボタンタップ済みで、かつ全てのメンバーが登録ボタンタップ済みの場合に、
        // 登録処理に移行する
        guard isConfirmedReadyRegistration,
              let myPeerID,
              let isLeadPeer = confirmedReadyRegistrationPeers.isLeadPeer(
                  connectedPeers: connectedPeers,
                  myPeerID: myPeerID
              ) else { return }

        registrationState = .processing(isLead: isLeadPeer)
    }

    func tappedRejectAlertButton() {
        isConfirmedReadyRegistration = false
    }

}
