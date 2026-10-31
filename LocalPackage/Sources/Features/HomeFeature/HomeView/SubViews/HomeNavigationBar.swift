//
//  HomeNavigationBar.swift
//  homete
//

import HometeUI
import SwiftUI

extension View {

    /// ダッシュボードのナビゲーションバー
    ///
    /// チュートリアルでもダッシュボードと同じナビゲーションバーを出すため、`HomeView`から切り出している
    /// - Parameter unreadAnnouncementCount: お知らせのベルに出す未読の数
    func homeNavigationBar(
        unreadAnnouncementCount: Int,
        onTapAnnouncement: @escaping () -> Void,
        onTapSetting: @escaping () -> Void
    ) -> some View {
        softTopScrollEdgeEffect()
            .trailingToolbarItem {
                HStack(spacing: .zero) {
                    NavigationBarButton(
                        label: .symbol("bell", accessibilityLabel: .localized("お知らせ")),
                        badgeCount: unreadAnnouncementCount,
                        action: onTapAnnouncement
                    )
                    NavigationBarButton(label: .settings, action: onTapSetting)
                }
            }
    }

}
