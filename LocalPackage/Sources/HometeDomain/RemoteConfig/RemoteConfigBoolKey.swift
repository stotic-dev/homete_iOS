//
//  RemoteConfigBoolKey.swift
//  LocalPackage
//

/// Remote Configで配信するBool値のキー
public enum RemoteConfigBoolKey: String, CaseIterable, Sendable {

    /// 広告表示を有効にするかどうか
    case adsEnabled = "ads_enabled"

    /// アプリ内デフォルト値
    /// - Note: 一度もactivateできていない（初回起動でオフラインなど）ときに使われる
    public var defaultValue: Bool {
        switch self {
        case .adsEnabled:
            // 取得できないときは広告を出さない安全側に倒す
            false
        }
    }

}
