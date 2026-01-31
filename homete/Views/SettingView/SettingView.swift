//
//  SettingView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct SettingView: View {
    
    @Environment(AccountStore.self) var accountStore
    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(\.loginContext.account.userName) var userName
    @Environment(\.dismiss) var dismiss
    @LoadingState var loadingState
    
    @State var isPresentedLogoutConfirmAlert = false
    @State var isPresentedAccountDeletionConfirmAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: .space32) {
                VStack(spacing: .space24) {
                    Text(userName)
                        .font(with: .headLineM)
                    Spacer()
                        .frame(height: .space16)
                    VStack(spacing: .zero) {
                        ForEach(SettingMenuItem.allCases, id: \.self) { item in
                            SettingMenuItemButton(item: item) {
                                // TODO: メニューボタンタップ時の処理
                            }
                        }
                    }
                }
                VStack(spacing: .space24) {
                    Button {
                        tappedLogoutRowButton()
                    } label: {
                        Text("ログアウト")
                            .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()
                    Button {
                        tappedAccountDeletionRowButton()
                    } label: {
                        Text("退会")
                            .frame(maxWidth: .infinity)
                    }
                    .destructiveButtonStyle()
                }
                Spacer()
            }
            .padding(.horizontal, .space16)
            .padding(.bottom, .space16)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    leadingNavigationBarContent()
                }
            }
        }
        .fullScreenLoadingIndicator(loadingState)
        .alert("ログアウトしますか？", isPresented: $isPresentedLogoutConfirmAlert) {
            Button("ログアウト", role: .destructive) {
                tappedLogoutAlertOkButton()
            }
        }
        .alert("退会しますか？", isPresented: $isPresentedAccountDeletionConfirmAlert) {
            Button("退会する", role: .destructive) {
                loadingState.task {
                    await tappedAccountDeletionAlertOkButton()
                }
            }
        } message: {
            Text("あなたのデータは全て削除され、復元することはできません。\nまた、現在参加しているグループが2名以下の場合は、グループごと削除されます。")
        }
    }
}

private extension SettingView {
    @ViewBuilder
    func leadingNavigationBarContent() -> some View {
        NavigationBarButton(label: .close) {
            dismiss()
        }
    }
}

// MARK: プレゼンテーションロジック

private extension SettingView {
    
    func tappedLogoutRowButton() {
        
        isPresentedLogoutConfirmAlert = true
    }
    
    func tappedLogoutAlertOkButton() {
        
        accountAuthStore.logOut()
    }
    
    func tappedAccountDeletionRowButton() {
        
        isPresentedAccountDeletionConfirmAlert = true
    }
    
    func tappedAccountDeletionAlertOkButton() async {
        
        do {
            
            try await accountAuthStore.deleteAccount()
        } catch {
            
            // TODO: エラーハンドリング
            print("occurred error: \(error)")
        }
    }
}

#Preview {
    SettingView()
        .environment(AccountAuthStore(appDependencies: .previewValue))
        .environment(AccountStore(appDependencies: .previewValue))
}
