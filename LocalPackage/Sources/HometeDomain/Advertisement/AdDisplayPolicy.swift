//
//  AdDisplayPolicy.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/23.
//

/// 広告を表示するかどうかを判定する
public enum AdDisplayPolicy {

    /// アプリ全体で広告表示を有効にするかどうか
    /// - Note: 本番環境で広告バナーを配信できないため、1.0.0では無効にしている。
    ///         広告を再開する場合はこの値を`true`に戻すだけでよい
    public static let isEnabled = false

    /// 広告を表示するかどうか
    /// - Parameters:
    ///   - isPremium: プレミアムプランに加入中かどうか
    ///   - isEnabled: アプリ全体で広告表示が有効かどうか（テスト用に差し替え可能）
    /// - Returns: 広告表示が有効かつ、プレミアムプラン未加入の場合に`true`
    public static func shouldShowAds(isPremium: Bool, isEnabled: Bool = isEnabled) -> Bool {
        isEnabled && !isPremium
    }

}
