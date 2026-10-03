//
//  ImplRemoteConfigClient.swift
//

import FirebaseRemoteConfig
import HometeDomain

extension RemoteConfigClient {

    static let liveValue: RemoteConfigClient = .init {
        _ = try await RemoteConfig.remoteConfig().fetchAndActivate()
    } bool: { key in
        RemoteConfig.remoteConfig().configValue(forKey: key.rawValue).boolValue
    }

}
