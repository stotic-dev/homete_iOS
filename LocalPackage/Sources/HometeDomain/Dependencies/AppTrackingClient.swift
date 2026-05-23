//
//  AppTrackingClient.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/23.
//

public enum AppTrackingAuthorizationStatus: Sendable {

    case notDetermined
    case restricted
    case denied
    case authorized

}

public struct AppTrackingClient: Sendable {

    public let requestTrackingAuthorization: @Sendable () async -> AppTrackingAuthorizationStatus

    public init(
        requestTrackingAuthorization: @Sendable @escaping () async -> AppTrackingAuthorizationStatus = {
            .notDetermined
        }
    ) {
        self.requestTrackingAuthorization = requestTrackingAuthorization
    }

}

public extension AppTrackingClient {

    static let previewValue: AppTrackingClient = .init()

}
