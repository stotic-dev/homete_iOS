//
//  SettingView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        VStack(spacing: .zero) {
            Spacer()
                .frame(height: DesignSystem.Space.space24)
            Text("Display Name")
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
                // TODO: ログアウト処理
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
    }
}

#Preview {
    NavigationStack {
        SettingView()
    }
}
