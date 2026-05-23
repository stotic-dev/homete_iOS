//
//  ConsentClient.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/23.
//

import Foundation

public protocol ConsentClientProtocol: Sendable {

    func requestConsentInfoUpdate() async throws
    func loadAndPresentConsentFormIfRequired() async throws
    func canRequestAds() async -> Bool

}

#if os(iOS)
    import UIKit
    import UserMessagingPlatform

    public final class ConsentClient: ConsentClientProtocol {

        public init() {}

        public func requestConsentInfoUpdate() async throws {
            try await requestConsentInfoUpdateOnMain()
        }

        public func loadAndPresentConsentFormIfRequired() async throws {
            try await loadAndPresentConsentFormIfRequiredOnMain()
        }

        public func canRequestAds() async -> Bool {
            await canRequestAdsOnMain()
        }

        @MainActor
        private func requestConsentInfoUpdateOnMain() async throws {
            let parameters = RequestParameters()
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
        }

        @MainActor
        private func loadAndPresentConsentFormIfRequiredOnMain() async throws {
            guard let rootViewController = Self.rootViewController() else { return }
            try await ConsentForm.loadAndPresentIfRequired(from: rootViewController)
        }

        @MainActor
        private func canRequestAdsOnMain() -> Bool {
            ConsentInformation.shared.canRequestAds
        }

        @MainActor
        private static func rootViewController() -> UIViewController? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
        }

    }
#endif
