//
//  SettingMenuSectionContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 設定画面のメニューを、区分の見出しとカードにまとめて表示する
struct SettingMenuSectionContent: View {

    let group: SettingMenuGroup
    let plan: SubscriptionPlan
    /// メニューに付ける件数のバッジ。0のときは付けない
    let badgeCount: (SettingMenuItem) -> Int
    let onTap: (SettingMenuItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(title(group.section))
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: .zero) {
                ForEach(Array(group.items.enumerated()), id: \.element) { index, item in
                    SettingMenuItemButton(item: item, plan: plan, badgeCount: badgeCount(item)) {
                        onTap(item)
                    }
                    if index < group.items.count - 1 {
                        Divider()
                            .padding(.leading, .space56)
                    }
                }
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space8)
            .background(.backgroundCard)
            .cornerRadius(.radius20)
        }
    }

}

// MARK: - UI定義

private extension SettingMenuSectionContent {

    func title(_ section: SettingMenuSection) -> LocalizedStringResource {
        switch section {
        case .group:
            .localized("グループ")

        case .housework:
            .localized("家事")

        case .app:
            .localized("アプリの設定")

        case .support:
            .localized("サポート")

        case .about:
            .localized("このアプリについて")

        #if DEBUG
        case .developer:
            .localized("開発者向け")
        #endif
        }
    }

}

// MARK: - Preview定義

#Preview("SettingMenuSectionContent_複数項目", traits: .sizeThatFitsLayout) {
    SettingMenuSectionContent(
        group: .init(section: .about, items: [.termsOfService, .privacyPolicy, .license]),
        plan: .free,
        badgeCount: { _ in 0 },
        onTap: { _ in }
    )
    .padding(.space16)
    .background(.backgroundScreen)
}

#Preview("SettingMenuSectionContent_未読あり", traits: .sizeThatFitsLayout) {
    SettingMenuSectionContent(
        group: .init(section: .support, items: [.inquiry]),
        plan: .free,
        badgeCount: { _ in 2 },
        onTap: { _ in }
    )
    .padding(.space16)
    .background(.backgroundScreen)
}
