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
    @Environment(\.connectedPeers) var connectedPeers
    @LoadingState var loadingState

    @CommonError var errorContent
    @State var sharingInvitation: CohabitantInvitation?

    /// メンバーを探している間の状態
    let scanning: CohabitantRegistrationState.Scanning
    let store: CohabitantRegistrationStore

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
            } else {
                CohabitantRegistrationPeersListView(
                    confirmedPeers: scanning.confirmedPeers,
                    isConfirmed: scanning.isConfirmed
                ) { isOK in
                    store.send(.userConfirmedMembers(isOK: isOK))
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
        .onAppear {
            scannerController.startScan()
        }
        .onDisappear {
            scannerController.finishScan()
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

}
