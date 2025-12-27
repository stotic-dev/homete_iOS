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
            HStack(spacing: .space16) {
                Image(systemName: item.iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.space8)
                    .foregroundStyle(.onSurface)
                    .background(.primary3)
                    .cornerRadius(.radius8)
                Text(item.title)
                    .font(with: .body)
                Spacer()
            }
            .foregroundStyle(.onSurface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .space8)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    SettingMenuItemButton(item: .taskTemplate) {}
}
