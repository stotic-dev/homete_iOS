//
//  AdDisplayPolicy.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/23.
//

/// 広告を表示するかどうかを判定する
public enum AdDisplayPolicy {

    /// 広告を表示するかどうか
    /// - Parameters:
    ///   - isPremium: プレミアムプランに加入中かどうか
    ///   - isEnabled: アプリ全体で広告表示が有効かどうか（Remote Configの`ads_enabled`）
    /// - Returns: 広告表示が有効かつ、プレミアムプラン未加入の場合に`true`
    public static func shouldShowAds(isPremium: Bool, isEnabled: Bool) -> Bool {
        isEnabled && !isPremium
    }

}
