//
//  SettingMenuItemButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//


import SwiftUI

struct SettingMenuItemButton: View {
    
    let item: SettingMenuItem
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: DesignSystem.Space.space16) {
                Image(systemName: item.iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(DesignSystem.Space.space8)
                    .foregroundStyle(.commonBlack)
                    .background(.primary3)
                    .cornerRadius(.radius8)
                Text(item.title)
                    .font(with: .body)
                Spacer()
            }
            .foregroundStyle(.primaryFg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Space.space8)
        }
    }
}

#Preview {
    SettingMenuItemButton(item: .taskTemplate) {}
}
