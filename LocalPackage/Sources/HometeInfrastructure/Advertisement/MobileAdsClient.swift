//
//  MobileAdsClient.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import Foundation
import GoogleMobileAds

public final class MobileAdsClient: Sendable {
    
    public static let shared = MobileAdsClient()
    
    public func initialize() async {
        await MobileAds.shared.start()
    }
}
