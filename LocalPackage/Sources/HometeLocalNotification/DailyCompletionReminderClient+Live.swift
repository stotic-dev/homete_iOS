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
        live(appGroupIdentifier: AppGroup.identifier)
    }

    /// 指定したApp GroupのUserDefaultsを使うlive実装
    /// - Parameter appGroupIdentifier: `nil`の場合は`UserDefaults.standard`を使う（拡張とは共有されない）
    static func live(appGroupIdentifier: String?) -> DailyCompletionReminderClient {
        .init(
            loadSetting: {
                guard let data = AppGroup.userDefaults(appGroupIdentifier).data(forKey: Self.settingKey),
                      let setting = try? JSONDecoder().decode(DailyCompletionReminderSetting.self, from: data) else {
                    return .initial
                }
                return setting
            },
            saveSetting: { setting in
                guard let data = try? JSONEncoder().encode(setting) else { return }
                AppGroup.userDefaults(appGroupIdentifier).set(data, forKey: Self.settingKey)
            },
            loadCompletedDayIdentifier: {
                AppGroup.userDefaults(appGroupIdentifier).string(forKey: Self.completedDayIdentifierKey)
            },
            saveCompletedDayIdentifier: { identifier in
                AppGroup.userDefaults(appGroupIdentifier).set(identifier, forKey: Self.completedDayIdentifierKey)
            },
            loadCompletedSignalSentDayIdentifier: {
                AppGroup.userDefaults(appGroupIdentifier).string(forKey: Self.completedSignalSentDayIdentifierKey)
            },
            saveCompletedSignalSentDayIdentifier: { identifier in
                AppGroup.userDefaults(appGroupIdentifier).set(
                    identifier,
                    forKey: Self.completedSignalSentDayIdentifierKey
                )
            },
            loadIsDailyLimitDisabled: {
                AppGroup.userDefaults(appGroupIdentifier).bool(forKey: Self.isDailyLimitDisabledKey)
            },
            saveIsDailyLimitDisabled: { isDisabled in
                AppGroup.userDefaults(appGroupIdentifier).set(isDisabled, forKey: Self.isDailyLimitDisabledKey)
            },
            schedule: { request in
                let content = UNMutableNotificationContent()
                // 予約した時点のアプリの言語で文面を決める
                content.title = DailyCompletionReminderRequest.title.resolved()
                content.body = request.body()
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: request.fireDateComponents, repeats: false)
                try await UNUserNotificationCenter.current().add(
                    UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger)
                )
            },
            cancel: { identifier in
                let center = UNUserNotificationCenter.current()
                let identifiers = await center.pendingNotificationRequests()
                    .map(\.identifier)
                    .filter { DailyCompletionReminderRequest.isIdentifier($0, ofDay: identifier) }
                center.removePendingNotificationRequests(withIdentifiers: identifiers)
            }
        )
    }

}

private extension DailyCompletionReminderClient {

    static let settingKey = "dailyCompletionReminderSetting"
    static let completedDayIdentifierKey = "dailyCompletionReminderCompletedDayIdentifier"
    static let completedSignalSentDayIdentifierKey = "dailyCompletionReminderCompletedSignalSentDayIdentifier"
    static let isDailyLimitDisabledKey = "dailyCompletionReminderIsDailyLimitDisabled"

}
