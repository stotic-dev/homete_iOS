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
    func homeNavigationBar(onTapSetting: @escaping () -> Void) -> some View {
        softTopScrollEdgeEffect()
            .trailingToolbarItem {
                NavigationBarButton(label: .settings, action: onTapSetting)
            }
    }

}
