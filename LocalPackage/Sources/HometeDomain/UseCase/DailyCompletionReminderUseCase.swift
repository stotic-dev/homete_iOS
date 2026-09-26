//
//  DailyCompletionReminderUseCase.swift
//  LocalPackage
//

import Foundation

/// 今日完了した家事がある日に、ユーザーが決めた時刻へふりかえり通知を予約するUseCase
///
/// 予約のきっかけは2つある。
/// - アプリで家事の一覧を購読している間に、今日の完了家事が見つかったとき（`syncToday`）
/// - アプリが起動していない間に、同居人から今日の家事の完了通知が届いたとき（`handleCompleted`。
///   Notification Service Extensionから呼ぶ）
///
/// 定期実行のサーバー処理を持たずに済むよう、条件を満たした端末自身がその日の通知を1件だけ予約する。
public final class DailyCompletionReminderUseCase: Sendable {

    private let client: DailyCompletionReminderClient

    public init(client: DailyCompletionReminderClient) {
        self.client = client
    }

    /// 現在の通知設定を返す
    public func loadSetting() async -> DailyCompletionReminderSetting {
        await client.loadSetting()
    }

    /// 家事の一覧から分かった「今日完了した家事があるか」に合わせて、今日の通知を予約・取消する
    /// - Note: 完了を取り消して0件に戻った場合は、予約済みの通知も取り消す
    public func syncToday(hasCompletedHousework: Bool, now: Date, calendar: Calendar) async {
        let identifier = DailyCompletionReminderRequest.identifier(for: now, calendar: calendar)
        guard hasCompletedHousework else {
            await client.saveCompletedDayIdentifier(nil)
            await client.cancel(identifier)
            return
        }

        await client.saveCompletedDayIdentifier(identifier)
        await scheduleToday(now: now, calendar: calendar)
    }

    /// 同居人から家事の完了通知を受け取ったときに、今日の家事なら今日の通知を予約する
    public func handleCompleted(_ data: HouseworkCompletedNotificationData, now: Date, calendar: Calendar) async {
        guard calendar.isDate(data.houseworkDate, inSameDayAs: now) else { return }

        let identifier = DailyCompletionReminderRequest.identifier(for: now, calendar: calendar)
        await client.saveCompletedDayIdentifier(identifier)
        await scheduleToday(now: now, calendar: calendar)
    }

    /// 通知設定を保存し、今日すでに完了した家事があれば新しい設定で予約し直す
    public func updateSetting(_ setting: DailyCompletionReminderSetting, now: Date, calendar: Calendar) async {
        await client.saveSetting(setting)

        let identifier = DailyCompletionReminderRequest.identifier(for: now, calendar: calendar)
        guard await client.loadCompletedDayIdentifier() == identifier else { return }

        await scheduleToday(now: now, calendar: calendar)
    }

}

private extension DailyCompletionReminderUseCase {

    /// 現在の設定で今日の通知を予約する。無効・時刻を過ぎている場合は予約を取り消す
    func scheduleToday(now: Date, calendar: Calendar) async {
        let setting = await client.loadSetting()
        guard let request = DailyCompletionReminderRequest.make(
            day: now,
            setting: setting,
            now: now,
            calendar: calendar
        ) else {
            await client.cancel(DailyCompletionReminderRequest.identifier(for: now, calendar: calendar))
            return
        }

        do {
            try await client.schedule(request)
        } catch {
            print("failed to schedule daily completion reminder: \(error)")
        }
    }

}
