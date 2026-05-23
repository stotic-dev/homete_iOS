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

    @MainActor
    private func requestConsentInfoUpdateOnMain() async throws {
        let parameters = RequestParameters()
        try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
    }

    @MainActor
    private func loadAndPresentConsentFormIfRequiredOnMain() async throws {
        guard let rootViewController = rootViewController() else { return }
        try await ConsentForm.loadAndPresentIfRequired(from: rootViewController)
    }

    @MainActor
    private func canRequestAdsOnMain() -> Bool {
        ConsentInformation.shared.canRequestAds
    }

    @MainActor
    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
#endif
