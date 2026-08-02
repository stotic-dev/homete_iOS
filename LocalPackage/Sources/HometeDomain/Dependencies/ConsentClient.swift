//
//  ConsentClient.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/23.
//

public struct ConsentClient: Sendable {

    public let requestConsentInfoUpdate: @Sendable () async throws -> Void
    public let loadAndPresentConsentFormIfRequired: @Sendable () async throws -> Void
    public let canRequestAds: @Sendable () async -> Bool

    public init(
        requestConsentInfoUpdate: @Sendable @escaping () async throws -> Void = {},
        loadAndPresentConsentFormIfRequired: @Sendable @escaping () async throws -> Void = {},
        canRequestAds: @Sendable @escaping () async -> Bool = { false }
    ) {
        self.requestConsentInfoUpdate = requestConsentInfoUpdate
        self.loadAndPresentConsentFormIfRequired = loadAndPresentConsentFormIfRequired
        self.canRequestAds = canRequestAds
    }

}

public extension ConsentClient {

    static let previewValue: ConsentClient = .init()

}
