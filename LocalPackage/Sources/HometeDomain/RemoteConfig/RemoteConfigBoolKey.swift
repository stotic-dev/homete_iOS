//
//  RemoteConfigBoolKey.swift
//  LocalPackage
//

/// Remote Configで配信するBool値のキー
public enum RemoteConfigBoolKey: String, CaseIterable, Sendable {

    /// 広告表示を有効にするかどうか
    case adsEnabled = "ads_enabled"
    /// アプリ全体をメンテナンス中にして、利用を止めるかどうか
    case maintenanceEnabled = "maintenance_enabled"

    /// アプリ内デフォルト値
    /// - Note: 一度もactivateできていない（初回起動でオフラインなど）ときに使われる
    public var defaultValue: Bool {
        switch self {
        case .adsEnabled:
            // 取得できないときは広告を出さない安全側に倒す
            false
        case .maintenanceEnabled:
            // 取得できないときはブロックしない安全側に倒す
            false
        }
    }

}
