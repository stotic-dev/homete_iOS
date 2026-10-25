//
//  MaintenanceStore.swift
//  LocalPackage
//

import Observation

/// アプリ全体がメンテナンス中かどうかを管理する
///
/// Remote Configの`maintenance_enabled`で切り替える。経緯は ADR-0055 を参照。
@MainActor
@Observable
public final class MaintenanceStore {

    /// メンテナンス中かどうか
    /// - Note: 早く止め、早く解除できるよう、新しい値を反映するたびに判定し直す
    public private(set) var isUnderMaintenance: Bool

    private let remoteConfigClient: RemoteConfigClient
    private let maintenanceStateClient: MaintenanceStateClient

    public init(
        remoteConfigClient: RemoteConfigClient = .previewValue,
        maintenanceStateClient: MaintenanceStateClient = .previewValue,
        isUnderMaintenance: Bool = false
    ) {
        self.remoteConfigClient = remoteConfigClient
        self.maintenanceStateClient = maintenanceStateClient
        self.isUnderMaintenance = isUnderMaintenance
    }

    /// 反映済みの値でメンテナンス中かどうかを判定し直し、Notification Service Extensionと共有する
    /// - Note: Boolとして読めない値は`false`になるため、設定ミスではブロックしない
    public func updateState() {
        isUnderMaintenance = remoteConfigClient.bool(.maintenanceEnabled)
        maintenanceStateClient.save(isUnderMaintenance)
    }

}
