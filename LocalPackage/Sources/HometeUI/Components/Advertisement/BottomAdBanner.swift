//
//  BottomAdBanner.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/08/22.
//

import HometeDomain
import HometeResources
import SwiftUI

/// 画面下部に固定表示する広告バナーと、Paywallへの導線をまとめたコンポーネント
struct BottomAdBanner: View {

    @Environment(\.adComponentResolver) var adComponentResolver

    let bannerType: BannerType
    let onTapPromotionLink: () -> Void

    var body: some View {
        VStack(spacing: .space4) {
            adComponentResolver.resolve(.banner(bannerType))
                // AdSizeBanner(320x50)の高さを確保する
                .frame(height: 50)
            RemoveAdsPromotionLink(action: onTapPromotionLink)
        }
        .padding(.top, .space8)
        // スクロール領域の内容が透けないように背景を敷く
        .background(.surface)
    }

}

public extension View {

    /// 画面下部に広告バナーを固定表示する
    /// - Parameters:
    ///   - bannerType: 表示するバナーの種別
    ///   - isPresented: 広告を表示するかどうか（プレミアムプラン加入中は`false`を渡す）
    ///   - onTapPromotionLink: 「広告を非表示にする」リンクをタップした際の処理
    func bottomAdBanner(
        _ bannerType: BannerType,
        isPresented: Bool,
        onTapPromotionLink: @escaping () -> Void
    ) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            if isPresented {
                BottomAdBanner(bannerType: bannerType, onTapPromotionLink: onTapPromotionLink)
            }
        }
    }

}
