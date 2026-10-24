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
    let plan: SubscriptionPlan
    /// 件数のバッジ。0のときは付けない
    var badgeCount = 0
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: .space16) {
                PedestalIcon(systemName: item.iconName)
                Text(item.title(plan: plan))
                    .font(with: .body)
                Spacer()
                if badgeCount > 0 {
                    countBadge()
                }
            }
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .space8)
        }
    }

}

// MARK: - UI定義

private extension SettingMenuItemButton {

    func countBadge() -> some View {
        Text(badgeCount, format: .number)
            .font(with: .boldCaption)
            .foregroundStyle(.textOnDestructive)
            .padding(.horizontal, .space8)
            .padding(.vertical, .space4)
            .background(.fillDestructive, in: Capsule())
            .accessibilityLabel(Text("未読\(badgeCount)件", bundle: #bundle))
    }

}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    SettingMenuItemButton(item: .taskTemplate, plan: .free) {}
}

#Preview("SettingMenuItemButton_未読あり", traits: .sizeThatFitsLayout) {
    SettingMenuItemButton(item: .inquiry, plan: .free, badgeCount: 3) {}
}

#Preview("プレミアムプラン_未登録", traits: .sizeThatFitsLayout) {
    SettingMenuItemButton(item: .premiumPlan, plan: .free) {}
}

#Preview("プレミアムプラン_登録済み_サブスク", traits: .sizeThatFitsLayout) {
    SettingMenuItemButton(
        item: .premiumPlan,
        plan: .subscription(
            period: .monthly,
            // VRTで日付表示がブレないよう固定値にする（TZ差で日付がずれないよう正午JST）
            nextRenewalDate: .previewDate(year: 2026, month: 6, day: 17, hour: 12),
            willRenew: true
        )
    ) {}
}
#endif
