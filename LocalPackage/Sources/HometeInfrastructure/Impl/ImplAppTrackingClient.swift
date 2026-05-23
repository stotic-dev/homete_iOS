//
//  ImplAppTrackingClient.swift
//

#if os(iOS)
    import AppTrackingTransparency
    import HometeDomain

    public extension AppTrackingClient {

        static let liveValue: AppTrackingClient = .init {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            return mapStatus(status)
        }

    }

    private func mapStatus(
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
#endif
