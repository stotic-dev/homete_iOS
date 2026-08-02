//
//  AdsSetupUseCase.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/23.
//

public final class AdsSetupUseCase: Sendable {

    private let consentClient: ConsentClient
    private let mobileAdsClient: MobileAdsClient

    public init(
        consentClient: ConsentClient,
        mobileAdsClient: MobileAdsClient
    ) {
        self.consentClient = consentClient
        self.mobileAdsClient = mobileAdsClient
    }

    public func setup() async {
        do {
            try await consentClient.requestConsentInfoUpdate()
            try await consentClient.loadAndPresentConsentFormIfRequired()
        } catch {
            print("[AdsSetupUseCase] consent setup failed: \(error)")
        }

        if await consentClient.canRequestAds() {
            await mobileAdsClient.initialize()
        }
    }

}
