//
//  AppGroup.swift
//  LocalPackage
//

import Foundation

/// アプリ本体とNotification Service Extensionで共有するApp Group
enum AppGroup {

    /// 実行中のアプリ・拡張のApp Groupの識別子
    /// - Note: ビルド構成ごとにバンドルIDが違うため、アプリ・拡張それぞれのInfo.plistの`AppGroupIdentifier`から読む
    static var identifier: String? {
        Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
    }

    /// App GroupのUserDefaultsを返す。App Groupが無い・読めない場合は`standard`を使う
    static func userDefaults(_ appGroupIdentifier: String?) -> UserDefaults {
        guard let appGroupIdentifier,
              !appGroupIdentifier.isEmpty,
              let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return .standard
        }
        return userDefaults
    }

}
