//
//  DailyCompletionReminderUseCase.swift
//  LocalPackage
//

import Foundation

/// 今日完了した家事がある日に、ユーザーが決めた時刻へふりかえり通知を予約するUseCase
///
/// 予約のきっかけは2つある。
/// - アプリで家事の一覧を購読している間に、今日の完了家事が見つかったとき（`syncToday`）
/// - アプリが起動していない間に、同居人から今日の家事の完了を知らせるサイレント通知が届いたとき
///   （`handleCompleted`）
///
/// 同居人の端末へのきっかけは、家事を完了した端末が`notifyCompletedIfNeeded`で送る。
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

    /// 1日1回の制限を外しているかを返す（デバッグメニュー用）
    public func loadIsDailyLimitDisabled() async -> Bool {
        await client.loadIsDailyLimitDisabled()
    }

    /// 1日1回の制限を外すかを保存する（デバッグメニュー用）
    /// - Note: 外している間は、きっかけが届くたびに同じ日の予約を上書きせず別の通知として積む
    public func updateIsDailyLimitDisabled(_ isDisabled: Bool) async {
        await client.saveIsDailyLimitDisabled(isDisabled)
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
        await scheduleToday(now: now, calendar: calendar, trigger: .houseworkList)
    }

    /// 同居人から家事の完了を知らせる通知を受け取ったときに、今日の家事なら今日の通知を予約する
    /// - Note: アプリのサイレント通知の受信と、Notification Service Extension（古いアプリからの完了通知）から呼ぶ
    /// - Parameter trigger: 呼び出し元の経路。1日1回の制限を外している間だけ通知の本文に載せる
    public func handleCompleted(
        _ data: HouseworkCompletedNotificationData,
        trigger: DailyCompletionReminderTrigger,
        now: Date,
        calendar: Calendar
    ) async {
        guard calendar.isDate(data.houseworkDate, inSameDayAs: now) else { return }

        let identifier = DailyCompletionReminderRequest.identifier(for: now, calendar: calendar)
        await client.saveCompletedDayIdentifier(identifier)
        await scheduleToday(now: now, calendar: calendar, trigger: trigger)
    }

    /// 同居人へ家事の完了を知らせるサイレント通知を、必要なときだけ送る
    ///
    /// 受け取った端末は今日の家事の完了でしか予約しないため、今日以外の家事では送らない。
    /// また、受け取った端末の予約は1日1件で足りるため、この端末からは1日1回だけ送る。
    /// 送信に失敗した場合は送信済みにせず、次の完了で送り直す。
    /// - Note: 端末ごとに記録するため、同居人も家事を完了すればその端末からも1回送られる（ベストエフォート）。
    ///         1日1回の制限を外している間（デバッグ用）は、受け取った端末で予約が積まれるよう毎回送る
    /// - Parameter send: サイレント通知を送る処理
    public func notifyCompletedIfNeeded(
        houseworkDate: Date,
        now: Date,
        calendar: Calendar,
        send: @Sendable (HouseworkCompletedNotificationData) async throws -> Void
    ) async throws {
        guard calendar.isDate(houseworkDate, inSameDayAs: now) else { return }

        let identifier = DailyCompletionReminderRequest.identifier(for: now, calendar: calendar)
        let isDailyLimitDisabled = await client.loadIsDailyLimitDisabled()
        let sentDayIdentifier = await client.loadCompletedSignalSentDayIdentifier()
        guard isDailyLimitDisabled || sentDayIdentifier != identifier else { return }

        try await send(.init(houseworkDate: houseworkDate))
        await client.saveCompletedSignalSentDayIdentifier(identifier)
    }

    /// 通知設定を保存し、今日すでに完了した家事があれば新しい設定で予約し直す
    public func updateSetting(_ setting: DailyCompletionReminderSetting, now: Date, calendar: Calendar) async {
        await client.saveSetting(setting)

        let identifier = DailyCompletionReminderRequest.identifier(for: now, calendar: calendar)
        guard await client.loadCompletedDayIdentifier() == identifier else { return }

        await scheduleToday(now: now, calendar: calendar, trigger: .settingChanged)
    }

}

private extension DailyCompletionReminderUseCase {

    /// 現在の設定で今日の通知を予約する。無効・時刻を過ぎている場合は予約を取り消す
    func scheduleToday(now: Date, calendar: Calendar, trigger: DailyCompletionReminderTrigger) async {
        let setting = await client.loadSetting()
        let isDailyLimitDisabled = await client.loadIsDailyLimitDisabled()
        guard let request = DailyCompletionReminderRequest.make(
            day: now,
            setting: setting,
            now: now,
            calendar: calendar,
            allowsMultiplePerDay: isDailyLimitDisabled,
            debugTrigger: isDailyLimitDisabled ? trigger : nil
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
