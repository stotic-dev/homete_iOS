//
//  SettingView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct SettingView: View {
    
    @Environment(\.rootNavigationPath) var rootNavigationPath
    @Environment(AccountStore.self) var accountStore
    @Environment(AccountAuthStore.self) var accountAuthStore
    
    @State var isPresentedLogoutConfirmAlert = false
    
    var body: some View {
        VStack(spacing: .zero) {
            Spacer()
                .frame(height: DesignSystem.Space.space24)
            Text(accountStore.account.displayName)
                .font(with: .headLineM)
            Spacer()
                .frame(height: DesignSystem.Space.space16)
            VStack(spacing: .zero) {
                ForEach(SettingMenuItem.allCases, id: \.self) { item in
                    SettingMenuItemButton(item: item) {
                        // TODO: メニューボタンタップ時の処理
                    }
                }
            }
            Spacer()
                .frame(height: DesignSystem.Space.space32)
            Button {
                isPresentedLogoutConfirmAlert = true
            } label: {
                Text("ログアウト")
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            Spacer(minLength: DesignSystem.Space.space16)
        }
        .padding(.horizontal, DesignSystem.Space.space16)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("設定")
        .alert("ログアウトしますか？", isPresented: $isPresentedLogoutConfirmAlert) {
            Button("ログアウト", role: .destructive) {
                accountAuthStore.logOut()
                rootNavigationPath.popToRoot()
            }
        }
        
    }
}

#Preview {
    NavigationStack {
        SettingView()
            .environment(AccountAuthStore(appDependencies: .previewValue))
    }
}
