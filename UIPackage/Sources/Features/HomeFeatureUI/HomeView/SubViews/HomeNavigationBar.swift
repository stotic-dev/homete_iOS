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
                HomeNavigationBarSpacer()
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationBarButton(label: .settings, action: onTapSetting)
                }
            }
        #endif
    }

}

#if os(iOS)
/// ナビゲーションバー右側のボタンの間に挟む`ToolbarSpacer`
///
/// - Note: `toolbar`の中に`if #available`を直に書くと、`homeNavigationBar`の戻り値の型に
///         SwiftUIの`buildLimitedAvailability`の不透明型が含まれる。Release構成ではモジュールをまたぐ最適化で
///         呼び出し側（HomeFeature）がこの型を直接参照するが、SwiftUIはこの型のシンボルを公開していないため
///         リンクに失敗する。型に包んで、呼び出し側から見える型に出さないようにする
private struct HomeNavigationBarSpacer: ToolbarContent {

    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
    }

}
#endif
