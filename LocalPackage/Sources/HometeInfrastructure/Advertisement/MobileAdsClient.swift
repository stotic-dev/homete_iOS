//
//  MobileAdsClient.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import Foundation
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

public final class MobileAdsClient: Sendable {

    public static let shared = MobileAdsClient()

    public func initialize() async {
        #if canImport(GoogleMobileAds)
        await MobileAds.shared.start()
        #endif
    }

}
