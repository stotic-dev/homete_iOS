//
//  BannerType+Extension.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import CoreGraphics
import Foundation
import HometeDomain
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

extension BannerType {

    /// バナーの配置方法
    ///
    /// AdMobは配置方法ごとに適したアダプティブサイズを用意しているので、それに合わせて使い分ける
    enum Layout {

        /// 画面の上端・下端に固定する（アンカー型アダプティブバナー）
        ///
        /// 高さは幅から事前に決まるので、読み込み前から広告の場所を確保できる
        case anchored
        /// スクロールするコンテンツの中に置く（インライン型アダプティブバナー）
        ///
        /// 高さは`maxHeight`以下の範囲で、読み込んだ広告に合わせて決まる
        case inline(maxHeight: CGFloat)

    }

    var unitId: String {
        let adsUnitIdDic = Bundle.main.object(forInfoDictionaryKey: "AdUnitIdList") as? [String: String] ?? [:]
        switch self {
        case .dashboardTop:
            return adsUnitIdDic["BANNER_DASHBOARD_TOP_AD_UNIT_ID"] ?? ""

        case .analyticsBottom:
            return adsUnitIdDic["BANNER_ANALYTICS_BOTTOM_AD_UNIT_ID"] ?? ""

        case .houseworkTemplateBottom:
            return adsUnitIdDic["BANNER_HOUSEWORK_TEMPLATE_BOTTOM_AD_UNIT_ID"] ?? ""
        }
    }

    var layout: Layout {
        switch self {
        case .dashboardTop:
            // ダッシュボードのカードの間に置くので、カードより目立たない高さに抑える
            .inline(maxHeight: 150)

        case .analyticsBottom, .houseworkTemplateBottom:
            .anchored
        }
    }

    #if canImport(GoogleMobileAds)
    /// 配置先の幅に合わせた広告サイズ
    @MainActor
    func adSize(width: CGFloat) -> AdSize {
        switch layout {
        case .anchored:
            largeAnchoredAdaptiveBanner(width: width)

        case let .inline(maxHeight):
            inlineAdaptiveBanner(width: width, maxHeight: maxHeight)
        }
    }
    #endif

}
