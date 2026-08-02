//
//  MobileAdsClient.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

public struct MobileAdsClient: Sendable {

    public let initialize: @Sendable () async -> Void

    public init(
        initialize: @Sendable @escaping () async -> Void = {}
    ) {
        self.initialize = initialize
    }

}

public extension MobileAdsClient {

    static let previewValue: MobileAdsClient = .init()

}
