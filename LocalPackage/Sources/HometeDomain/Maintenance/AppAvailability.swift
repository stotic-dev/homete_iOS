//
//  AppAvailability.swift
//  LocalPackage
//

/// アプリを使える状態か、どの理由で利用を止めているか
public enum AppAvailability: Equatable, Sendable {

    /// 使える
    case available
    /// メンテナンス中のため止めている
    case underMaintenance
    /// 強制アップデートが必要なため止めている
    case updateRequired

    /// - Note: 両方に当てはまる場合はメンテナンスを優先する。アップデートしてもメンテナンス中は使えないため
    public init(isUnderMaintenance: Bool, isForceUpdateRequired: Bool) {
        if isUnderMaintenance {
            self = .underMaintenance
        } else if isForceUpdateRequired {
            self = .updateRequired
        } else {
            self = .available
        }
    }

}
