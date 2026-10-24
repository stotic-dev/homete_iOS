//
//  ImplDebugLocalDataClient.swift
//  LocalPackage
//

#if DEBUG

import Foundation
import HometeDomain

extension DebugLocalDataClient {

    static let liveValue: DebugLocalDataClient = .init(
        removeAll: {
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
            }
            // ふりかえり通知の設定と記録は、通知拡張と共有するApp GroupのUserDefaultsに置いている
            if let appGroupIdentifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String {
                UserDefaults(suiteName: appGroupIdentifier)?.removePersistentDomain(forName: appGroupIdentifier)
            }
        }
    )

}

#endif
