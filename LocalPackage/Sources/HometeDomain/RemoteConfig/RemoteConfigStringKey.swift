//
//  RemoteConfigStringKey.swift
//  LocalPackage
//

/// Remote Configで配信する文字列のキー
public enum RemoteConfigStringKey: String, CaseIterable, Sendable {

    /// これより古いバージョンは利用できなくする最低バージョン（例: `1.4.0`）
    case minimumRequiredVersion = "minimum_required_version"

    /// アプリ内デフォルト値
    /// - Note: 一度もactivateできていない（初回起動でオフラインなど）ときに使われる
    public var defaultValue: String {
        switch self {
        case .minimumRequiredVersion:
            // 取得できないときはブロックしない安全側に倒す
            ""
        }
    }

}
