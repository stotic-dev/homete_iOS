//
//  CohabitantRegistrationView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import HometeDomain
import HometeUI
import MultipeerConnectivity
import SwiftUI

public struct CohabitantRegistrationView: View {

    @Environment(\.loginContext.account.userName) var userName
    @Environment(\.dismiss) var dismiss
    @Environment(AccountStore.self) var accountStore
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @LoadingState var loadingState
    @CommonError var errorContent

    public init() {}

    /// 登録処理を中断するかどうかを確認するアラート
    @State var isPresentingConfirmCancelAlert = false
    /// Firestore上にアカウントがあることを確認できたかどうか
    /// - Note: 確認できるまでP2Pセッションを張らない
    @State var isVerifiedAccount = false

    public var body: some View {
        NavigationStack {
            ZStack {
                if isVerifiedAccount {
                    P2PSession(displayName: userName) {
                        CohabitantRegistrationSession(session: $0)
                    }
                }
            }
            .fullScreenLoadingIndicator(loadingState)
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    isPresentingConfirmCancelAlert = true
                }
            }
        }
        .commonError(content: $errorContent) {
            dismiss()
        }
        .alert(
            "登録処理を終了しますか？",
            isPresented: $isPresentingConfirmCancelAlert
        ) {
            Button(role: .destructive) {
                dismiss()
            } label: {
                Text("終了する")
            }
        } message: {
            Text("登録を終了すると、また初めから登録し直す必要があります。")
        }
        .onCompleteCohabitantRegistration { cohabitantId in
            try await onCompleteCohabitantRegistration(cohabitantId)
        }
        .onAppear {
            analyticsClient.log(.cohabitantRegistration(.started(method: .p2p)))
        }
        .task {
            await verifyAccount()
        }
        .trackScreenView(.cohabitantRegistration)
    }

}

// MARK: プレゼンテーションロジック

private extension CohabitantRegistrationView {

    /// Firestore上にアカウントがあることを確認してからP2Pセッションを開始する
    /// - Note: アカウントが無いままP2P登録を進めると、同居人IDの保存（`registerCohabitantId`）で
    ///         落ちるまで気づけないため、セッションを張る前にエラーとして閉じる
    func verifyAccount() async {
        loadingState.isLoading = true
        defer { loadingState.isLoading = false }

        do {
            try await accountStore.reload()
            isVerifiedAccount = true
        } catch {
            errorContent = .init(error: error)
        }
    }

    func onCompleteCohabitantRegistration(_ cohabitantId: String) async throws {
        do {
            try await accountStore.registerCohabitantId(cohabitantId)
            analyticsClient.log(.cohabitantRegistration(.completed(method: .p2p, isSuccess: true)))
        } catch {
            print("error occurred: \(error)")
            analyticsClient.log(.cohabitantRegistration(.completed(method: .p2p, isSuccess: false)))
            throw error
        }
    }

}
