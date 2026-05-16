//
//  BannerType+Extension.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

#if os(iOS)
    import Foundation
    import GoogleMobileAds
    import HometeDomain

    extension BannerType {

        var unitId: String {
            let adsUnitIdDic = Bundle.main.object(forInfoDictionaryKey: "AdUnitIdList") as? [String: String] ?? [:]
            switch self {
            case .dashboardTop:
                return adsUnitIdDic["BANNER_DASHBOARD_TOP_AD_UNIT_ID"] ?? ""
            }
        }

        var size: AdSize {
            switch self {
            case .dashboardTop: AdSizeBanner
            }
        }

    }
#endif
