//
//  BannerType+Extension.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import Foundation
import HometeDomain
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

extension BannerType {

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

    #if canImport(GoogleMobileAds)
    var size: AdSize {
        switch self {
        case .dashboardTop, .analyticsBottom, .houseworkTemplateBottom: AdSizeBanner
        }
    }
    #endif

}
