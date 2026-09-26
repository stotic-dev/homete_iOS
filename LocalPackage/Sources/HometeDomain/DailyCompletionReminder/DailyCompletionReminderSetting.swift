//
//  DailyCompletionReminderSetting.swift
//  LocalPackage
//

/// 当日に完了した家事がある日に、ふりかえりの通知を出す時刻の設定
/// - Note: 端末ごとの設定のため、Firestoreには保存しない。
///         アプリ本体とNotification Service Extensionの両方から読むため、App Groupで共有する
public struct DailyCompletionReminderSetting: Equatable, Codable, Sendable {

    /// 通知を出すかどうか
    public let isEnabled: Bool
    /// 通知を出す時（0〜23）
    public let hour: Int
    /// 通知を出す分（0〜59）
    public let minute: Int

    public init(isEnabled: Bool, hour: Int, minute: Int) {
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
    }

}

public extension DailyCompletionReminderSetting {

    /// 未設定時の値
    /// - Note: 家事がひと段落しやすい夜の時間帯を初期値にする。設定を開かなくても届くよう、初期状態からONにする
    static let initial: Self = .init(isEnabled: true, hour: 21, minute: 0)

    /// 有効/無効だけを差し替えた設定を返す
    func updateIsEnabled(_ isEnabled: Bool) -> Self {
        .init(isEnabled: isEnabled, hour: hour, minute: minute)
    }

    /// 時刻だけを差し替えた設定を返す
    func updateTime(hour: Int, minute: Int) -> Self {
        .init(isEnabled: isEnabled, hour: hour, minute: minute)
    }

}
