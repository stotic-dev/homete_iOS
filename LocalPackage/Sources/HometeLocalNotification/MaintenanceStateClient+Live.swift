//
//  MaintenanceStateClient+Live.swift
//  LocalPackage
//

import Foundation
import HometeDomain

public extension MaintenanceStateClient {

    /// アプリ本体とNotification Service Extensionで共有するlive実装
    /// - Note: App GroupのUserDefaultsに保存する
    static var liveValue: MaintenanceStateClient {
        let appGroupIdentifier = AppGroup.identifier
        return .init(
            load: {
                AppGroup.userDefaults(appGroupIdentifier).bool(forKey: isUnderMaintenanceKey)
            },
            save: { isUnderMaintenance in
                AppGroup.userDefaults(appGroupIdentifier).set(isUnderMaintenance, forKey: isUnderMaintenanceKey)
            }
        )
    }

}

private extension MaintenanceStateClient {

    static let isUnderMaintenanceKey = "maintenanceIsUnderMaintenance"

}
