//
//  ImplConsentClient.swift
//

#if os(iOS)
import HometeDomain
import UIKit
import UserMessagingPlatform

public extension ConsentClient {

    static let liveValue: ConsentClient = .init {
        try await requestConsentInfoUpdateOnMain()
    } loadAndPresentConsentFormIfRequired: {
        try await loadAndPresentConsentFormIfRequiredOnMain()
    } canRequestAds: {
        await canRequestAdsOnMain()
    }

}

private extension ConsentClient {

    @MainActor
    static func requestConsentInfoUpdateOnMain() async throws {
        let parameters = RequestParameters()
        try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
    }

    @MainActor
    static func loadAndPresentConsentFormIfRequiredOnMain() async throws {
        guard let rootViewController = rootViewController() else { return }
        try await ConsentForm.loadAndPresentIfRequired(from: rootViewController)
    }

    @MainActor
    static func canRequestAdsOnMain() -> Bool {
        ConsentInformation.shared.canRequestAds
    }

    @MainActor
    static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

}
#endif
