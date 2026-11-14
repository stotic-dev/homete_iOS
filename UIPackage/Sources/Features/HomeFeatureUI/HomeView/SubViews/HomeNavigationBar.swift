//
//  HomeNavigationBar.swift
//  homete
//

import HometeModel
import HometeUI
import SwiftUI

public extension View {

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
        #if os(iOS)
            .toolbar {
                // 1つの`ToolbarItem`にまとめるとiOS26でガラスの背景がひとつながりになるため、`ToolbarSpacer`で分けて出す
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationBarButton(
                        label: .symbol("bell", accessibilityLabel: .localized("お知らせ")),
                        badgeCount: unreadAnnouncementCount,
                        action: onTapAnnouncement
                    )
                }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationBarButton(label: .settings, action: onTapSetting)
                }
            }
        #endif
    }

}
