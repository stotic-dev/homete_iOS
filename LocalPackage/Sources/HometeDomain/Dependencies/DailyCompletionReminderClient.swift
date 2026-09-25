//
//  DailyCompletionReminderClient.swift
//  LocalPackage
//

/// ふりかえり通知の設定の永続化と、ローカル通知の予約・取消を行うClient
/// - Note: アプリ本体とNotification Service Extensionの両方から使う。
///         どちらのプロセスから予約しても、OSが保持するアプリの通知として指定時刻に表示される
public struct DailyCompletionReminderClient: Sendable {

    /// 通知の設定を読み出す（未設定なら`DailyCompletionReminderSetting.initial`）
    public let loadSetting: @Sendable () async -> DailyCompletionReminderSetting
    /// 通知の設定を保存する
    public let saveSetting: @Sendable (DailyCompletionReminderSetting) async -> Void
    /// 完了した家事があると最後に分かった日の通知識別子を読み出す
    public let loadCompletedDayIdentifier: @Sendable () async -> String?
    /// 完了した家事があると分かった日の通知識別子を保存する（`nil`で消去）
    public let saveCompletedDayIdentifier: @Sendable (String?) async -> Void
    /// ローカル通知を予約する。同じ識別子の予約は上書きされる
    public let schedule: @Sendable (DailyCompletionReminderRequest) async throws -> Void
    /// 指定した識別子の予約を取り消す
    public let cancel: @Sendable (_ identifier: String) async -> Void

    public init(
        loadSetting: @Sendable @escaping () async -> DailyCompletionReminderSetting = { .initial },
        saveSetting: @Sendable @escaping (DailyCompletionReminderSetting) async -> Void = { _ in },
        loadCompletedDayIdentifier: @Sendable @escaping () async -> String? = { nil },
        saveCompletedDayIdentifier: @Sendable @escaping (String?) async -> Void = { _ in },
        schedule: @Sendable @escaping (DailyCompletionReminderRequest) async throws -> Void = { _ in },
        cancel: @Sendable @escaping (_ identifier: String) async -> Void = { _ in }
    ) {
        self.loadSetting = loadSetting
        self.saveSetting = saveSetting
        self.loadCompletedDayIdentifier = loadCompletedDayIdentifier
        self.saveCompletedDayIdentifier = saveCompletedDayIdentifier
        self.schedule = schedule
        self.cancel = cancel
    }

}

public extension DailyCompletionReminderClient {

    static let previewValue: DailyCompletionReminderClient = .init()

}
