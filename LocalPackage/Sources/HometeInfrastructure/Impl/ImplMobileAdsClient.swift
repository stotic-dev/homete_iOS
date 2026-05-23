//
//  ImplMobileAdsClient.swift
//

import HometeDomain
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

public extension MobileAdsClient {
    
    static let liveValue: MobileAdsClient = .init {
        await MobileAds.shared.start()
    }
    
}
