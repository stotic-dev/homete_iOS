//
//  ImplMobileAdsClient.swift
//

import HometeDomain
import HometeDomainUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

public extension MobileAdsClient {

    static let liveValue: MobileAdsClient = .init {
        #if canImport(GoogleMobileAds)
        await MobileAds.shared.start()
        #endif
    }

}
