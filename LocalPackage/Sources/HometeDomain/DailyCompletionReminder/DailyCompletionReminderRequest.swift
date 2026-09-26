//
//  DailyCompletionReminderRequest.swift
//  LocalPackage
//

import Foundation

/// OSへ予約するふりかえり通知1件分の内容
public struct DailyCompletionReminderRequest: Equatable, Sendable {

    /// 通知の識別子。同じ日の予約は同じ値になるため、何度予約しても1件に上書きされる
    /// - Note: 1日1回の制限を外している場合（デバッグ用）は、予約ごとに別の値になる
    public let identifier: String
    /// 通知を出す日時（年月日時分）
    public let fireDateComponents: DateComponents
    public let title: String
    public let body: String

    public init(identifier: String, fireDateComponents: DateComponents, title: String, body: String) {
        self.identifier = identifier
        self.fireDateComponents = fireDateComponents
        self.title = title
        self.body = body
    }

}

public extension DailyCompletionReminderRequest {

    /// 指定した日のふりかえり通知の識別子
    static func identifier(for day: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        let year = components.year ?? .zero
        let month = components.month ?? .zero
        let dayOfMonth = components.day ?? .zero
        return "dailyCompletionReminder-\(year)-\(month)-\(dayOfMonth)"
    }

    /// 予約の識別子が、指定した日のふりかえり通知のものかどうか
    /// - Note: 1日1回の制限を外して予約した通知も、その日の通知として扱う
    static func isIdentifier(_ requestIdentifier: String, ofDay dayIdentifier: String) -> Bool {
        requestIdentifier == dayIdentifier
            || requestIdentifier.hasPrefix(dayIdentifier + multiplePerDaySeparator)
    }

    /// 指定した日のふりかえり通知を組み立てる
    /// - Parameter allowsMultiplePerDay: `true`の場合は予約ごとに識別子を変え、同じ日の予約を上書きせずに積む
    ///   （動作確認用。デバッグメニューから切り替える）
    /// - Returns: 通知が無効な場合、または指定時刻をすでに過ぎている場合は`nil`
    static func make(
        day: Date,
        setting: DailyCompletionReminderSetting,
        now: Date,
        calendar: Calendar,
        allowsMultiplePerDay: Bool = false
    ) -> Self? {
        guard setting.isEnabled else { return nil }

        // Calendarが返すDateComponentsには`isLeapMonth`なども入るため、必要な値だけで組み直す
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let components = DateComponents(
            year: dayComponents.year,
            month: dayComponents.month,
            day: dayComponents.day,
            hour: setting.hour,
            minute: setting.minute
        )
        guard let fireDate = calendar.date(from: components),
              fireDate > now else { return nil }

        let dayIdentifier = identifier(for: day, calendar: calendar)
        return .init(
            identifier: allowsMultiplePerDay
                ? "\(dayIdentifier)\(multiplePerDaySeparator)\(Int(now.timeIntervalSince1970))"
                : dayIdentifier,
            fireDateComponents: components,
            title: "今日もおつかれさまでした",
            body: "今日完了した家事があります。ふりかえって、感謝を伝え合いましょう"
        )
    }

}

private extension DailyCompletionReminderRequest {

    /// 1日1回の制限を外して予約するときに、日の識別子と予約ごとの値を区切る文字
    static let multiplePerDaySeparator = "#"

}
