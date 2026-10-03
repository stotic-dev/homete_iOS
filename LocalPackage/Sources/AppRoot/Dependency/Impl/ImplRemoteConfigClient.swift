//
//  ImplRemoteConfigClient.swift
//

import FirebaseRemoteConfig
import HometeDomain

extension RemoteConfigClient {

    static let liveValue: RemoteConfigClient = .init(
        fetchAndActivate: {
            _ = try await RemoteConfig.remoteConfig().fetchAndActivate()
        },
        configUpdates: {
            AsyncStream { continuation in
                let registration = RemoteConfig.remoteConfig().addOnConfigUpdateListener { configUpdate, error in
                    guard configUpdate != nil else {
                        // Realtime APIが無効・通信エラーなど。復帰時のfetchで追いつくため、ここでは何もしない
                        print("[RemoteConfigClient] failed to receive config update: \(String(describing: error))")
                        return
                    }
                    // リスナーが受け取った時点では取得済みなだけで、activateしないとアプリからは読めない
                    RemoteConfig.remoteConfig().activate { _, error in
                        if let error {
                            print("[RemoteConfigClient] failed to activate config update: \(error)")
                            return
                        }
                        continuation.yield()
                    }
                }
                continuation.onTermination = { _ in
                    registration.remove()
                }
            }
        },
        bool: { key in
            RemoteConfig.remoteConfig().configValue(forKey: key.rawValue).boolValue
        },
        string: { key in
            RemoteConfig.remoteConfig().configValue(forKey: key.rawValue).stringValue
        }
    )

}
