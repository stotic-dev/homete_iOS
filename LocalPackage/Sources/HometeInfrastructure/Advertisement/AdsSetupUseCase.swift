//
//  AdsSetupUseCase.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/23.
//

import Foundation

public final class AdsSetupUseCase: Sendable {

    private let consentClient: any ConsentClientProtocol
    private let appTrackingClient: any AppTrackingClientProtocol
    private let mobileAdsClient: any MobileAdsClientProtocol

    public init(
        consentClient: any ConsentClientProtocol,
        appTrackingClient: any AppTrackingClientProtocol,
        mobileAdsClient: any MobileAdsClientProtocol
    ) {
        self.consentClient = consentClient
        self.appTrackingClient = appTrackingClient
        self.mobileAdsClient = mobileAdsClient
    }

    public func setup() async {
        do {
            try await consentClient.requestConsentInfoUpdate()
            try await consentClient.loadAndPresentConsentFormIfRequired()
        } catch {
            print("[AdsSetupUseCase] consent setup failed: \(error)")
        }

        _ = await appTrackingClient.requestTrackingAuthorization()

        if await consentClient.canRequestAds() {
            await mobileAdsClient.initialize()
        }
    }

}

#if os(iOS)
    public extension AdsSetupUseCase {

        static let live = AdsSetupUseCase(
            consentClient: ConsentClient(),
            appTrackingClient: AppTrackingClient(),
            mobileAdsClient: MobileAdsClient.shared
        )

    }
#endif
