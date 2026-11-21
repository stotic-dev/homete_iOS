//
//  NavigationBarButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

public struct NavigationBarButton: View {

    public let label: NavigationBarContentLabel
    /// アイコンの右上に出す件数。0なら出さない
    public let badgeCount: Int
    public let action: () -> Void

    public init(label: NavigationBarContentLabel, badgeCount: Int = 0, action: @escaping () -> Void) {
        self.label = label
        self.badgeCount = badgeCount
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            label.icon
                // アイコンを隠さないよう、バッジはアイコンの右上の角から右上へ伸ばし、角に少しだけ掛ける。
                // 件数の桁が増えても左（アイコン側）へは広がらないよう、角に置いた大きさ0の点を起点にする
                .overlay(alignment: .topTrailing) {
                    if badgeCount > 0 {
                        Color.clear
                            .frame(width: .zero, height: .zero)
                            .overlay(alignment: .bottomLeading) {
                                countBadge()
                                    .offset(x: -6, y: 8)
                            }
                    }
                }
                .padding(.space8)
                .foregroundStyle(.textPrimary)
        }
        .accessibilityLabel(label.accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

}

// MARK: - UI定義

private extension NavigationBarButton {

    func countBadge() -> some View {
        // 3桁になるとナビゲーションバーの隣のボタンに重なるため、99件を超えたらまとめる
        Text(verbatim: badgeCount > 99 ? "99+" : "\(badgeCount)")
            .font(with: .boldCaption)
            .foregroundStyle(.textOnDestructive)
            .padding(.horizontal, .space4)
            .frame(minWidth: 18, minHeight: 18)
            .background(.fillDestructive, in: Capsule())
            .fixedSize()
    }

    var accessibilityValue: Text {
        badgeCount > 0 ? Text("未読\(badgeCount)件", bundle: #bundle) : Text(verbatim: "")
    }

}

// MARK: - Preview定義

#if DEBUG
#Preview("NavigationBarButton_バッジなし", traits: .sizeThatFitsLayout) {
    NavigationBarButton(label: .settings) {}
        .padding(.space8)
}

#Preview("NavigationBarButton_バッジあり", traits: .sizeThatFitsLayout) {
    HStack {
        NavigationBarButton(label: .settings, badgeCount: 3) {}
        NavigationBarButton(label: .settings, badgeCount: 120) {}
    }
    .padding(.space8)
}
#endif
