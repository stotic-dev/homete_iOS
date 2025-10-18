//
//  CohabitantRegistrationView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationView: View {
    
    @Environment(AccountStore.self) var accountStore
    @Environment(\.dismiss) var dismiss
    
    // 登録処理を中断するかどうかを確認するアラート
    @State var isPresentingConfirmCancelAlert = false
    
    var body: some View {
        NavigationStack {
            P2PSession(displayName: accountStore.account.displayName) {
                CohabitantRegistrationSession(session: $0)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationBarButton(label: .close) {
                        isPresentingConfirmCancelAlert = true
                    }
                }
            }
        }
        .alert(
            "登録処理を終了しますか？",
            isPresented: $isPresentingConfirmCancelAlert) {
                Button(role: .destructive) {
                    dismiss()
                } label: {
                    Text("終了する")
                }
            } message: {
                Text("登録を終了すると、また初めから登録し直す必要があります。")
            }
    }
}

#Preview("CohabitantRegistrationView_登録終了確認アラート表示") {
    CohabitantRegistrationView(isPresentingConfirmCancelAlert: true)
        .environment(AccountStore(appDependencies: .previewValue))
}
