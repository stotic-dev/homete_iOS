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
    
    @Environment(\.calendar) var calendar
    @Environment(\.loginContext.account.userName) var userName
    @Environment(\.dismiss) var dismiss
    @Environment(\.appDependencies.houseworkManager) var houseworkManager
    @Environment(\.now) var now
    @Environment(AccountStore.self) var accountStore
    
    public init() {}

    // 登録処理を中断するかどうかを確認するアラート
    @State var isPresentingConfirmCancelAlert = false
    
    public var body: some View {
        NavigationStack {
            P2PSession(displayName: userName) {
                CohabitantRegistrationSession(session: $0)
            }
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    isPresentingConfirmCancelAlert = true
                }
            }
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
            Task {
                await onCompleteCohabitantRegistration(cohabitantId)
            }
        }
    }
}

// MARK: プレゼンテーションロジック

private extension CohabitantRegistrationView {
    
    func onCompleteCohabitantRegistration(_ cohabitantId: String) async {
        
        do {
            
            try await accountStore.registerCohabitantId(cohabitantId)
            await houseworkManager.setupObserver(
                currentTime: now,
                cohabitantId: cohabitantId,
                calendar: calendar,
                offset: 3 // TODO: 定数を使うようにする
            )
        } catch {
            
            print("error occurred: \(error)")
        }
    }
}
