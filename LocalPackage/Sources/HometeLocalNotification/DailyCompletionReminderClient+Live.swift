//
//  DailyCompletionReminderClient+Live.swift
//  LocalPackage
//

import Foundation
import HometeDomain
import UserNotifications

public extension DailyCompletionReminderClient {

    /// アプリ本体とNotification Service Extensionで共有するlive実装
    /// - Note: 設定はApp GroupのUserDefaultsに保存する。App Groupの識別子は、アプリ・拡張それぞれの
    ///         Info.plistの`AppGroupIdentifier`から読む（ビルド構成ごとにバンドルIDが違うため）
    static var liveValue: DailyCompletionReminderClient {
        live(appGroupIdentifier: Bundle.main.object(forInfoDictionaryKey: Self.appGroupIdentifierInfoKey) as? String)
    }

    /// 指定したApp GroupのUserDefaultsを使うlive実装
    /// - Parameter appGroupIdentifier: `nil`の場合は`UserDefaults.standard`を使う（拡張とは共有されない）
    static func live(appGroupIdentifier: String?) -> DailyCompletionReminderClient {
        .init(
            loadSetting: {
                guard let data = Self.userDefaults(appGroupIdentifier).data(forKey: Self.settingKey),
                      let setting = try? JSONDecoder().decode(DailyCompletionReminderSetting.self, from: data) else {
                    return .initial
                }
                return setting
            },
            saveSetting: { setting in
                guard let data = try? JSONEncoder().encode(setting) else { return }
                Self.userDefaults(appGroupIdentifier).set(data, forKey: Self.settingKey)
            },
            loadCompletedDayIdentifier: {
                Self.userDefaults(appGroupIdentifier).string(forKey: Self.completedDayIdentifierKey)
            },
            saveCompletedDayIdentifier: { identifier in
                Self.userDefaults(appGroupIdentifier).set(identifier, forKey: Self.completedDayIdentifierKey)
            },
            schedule: { request in
                let content = UNMutableNotificationContent()
                content.title = request.title
                content.body = request.body
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: request.fireDateComponents, repeats: false)
                try await UNUserNotificationCenter.current().add(
                    UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger)
                )
            },
            cancel: { identifier in
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            }
        )
    }

}

private extension DailyCompletionReminderClient {

    static let appGroupIdentifierInfoKey = "AppGroupIdentifier"
    static let settingKey = "dailyCompletionReminderSetting"
    static let completedDayIdentifierKey = "dailyCompletionReminderCompletedDayIdentifier"

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
