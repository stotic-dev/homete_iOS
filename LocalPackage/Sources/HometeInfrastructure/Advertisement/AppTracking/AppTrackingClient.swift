//
//  AppTrackingClient.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/23.
//

import Foundation

public enum AppTrackingAuthorizationStatus: Sendable {

    case notDetermined
    case restricted
    case denied
    case authorized

}

public protocol AppTrackingClientProtocol: Sendable {

    func requestTrackingAuthorization() async -> AppTrackingAuthorizationStatus

}

#if os(iOS)
    import AppTrackingTransparency

    public final class AppTrackingClient: AppTrackingClientProtocol {

        public init() {}

        public func requestTrackingAuthorization() async -> AppTrackingAuthorizationStatus {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            return Self.map(status)
        }

        private static func map(
            _ status: ATTrackingManager.AuthorizationStatus
        ) -> AppTrackingAuthorizationStatus {
            switch status {
            case .notDetermined: .notDetermined
            case .restricted: .restricted
            case .denied: .denied
            case .authorized: .authorized
            @unknown default: .notDetermined
            }
        }

    }
#endif
