//
//  ForceUpdatePolicy.swift
//  LocalPackage
//

/// 強制アップデートが必要かどうかの判定
public enum ForceUpdatePolicy {

    /// 現在のバージョンが最低バージョンを下回っていれば、強制アップデートが必要と判定する
    /// - Returns: どちらかのバージョンが空・不正な値の場合は`false`
    /// - Note: 誤設定でユーザー全員を締め出さないよう、判定できないときはブロックしない側に倒す
    public static func isRequired(currentVersion: String, minimumRequiredVersion: String) -> Bool {
        guard let current = AppVersion(currentVersion),
              let minimum = AppVersion(minimumRequiredVersion) else { return false }
        return current < minimum
    }

}
