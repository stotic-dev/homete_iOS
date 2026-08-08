//
//  SettingMenuItemButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

struct SettingMenuItemButton: View {

    let item: SettingMenuItem
    var isPremium = false
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
                Text(item.title(isPremium: isPremium))
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

#Preview("プレミアムプラン_未登録", traits: .sizeThatFitsLayout) {
    SettingMenuItemButton(item: .premiumPlan, isPremium: false) {}
}

#Preview("プレミアムプラン_登録済み", traits: .sizeThatFitsLayout) {
    SettingMenuItemButton(item: .premiumPlan, isPremium: true) {}
}
