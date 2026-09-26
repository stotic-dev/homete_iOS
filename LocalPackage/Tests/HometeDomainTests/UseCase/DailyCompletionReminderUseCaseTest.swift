//
//  DailyCompletionReminderUseCaseTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

enum DailyCompletionReminderUseCaseTest {

    struct SyncTodayCase {}
    struct HandleCompletedCase {}
    struct UpdateSettingCase {}
    struct DailyLimitCase {}
    struct NotifyCompletedCase {}

}

// MARK: - syncToday

extension DailyCompletionReminderUseCaseTest.SyncTodayCase {

    @Test("今日完了した家事があれば、完了日を記録して今日の通知を予約する")
    func syncToday_hasCompletedHousework_schedulesTodayReminder() async {
        // Arrange

        let store = ReminderClientStore(setting: .init(isEnabled: true, hour: 21, minute: 0))
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = ReminderClientSnapshot(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-25",
            entries: [.schedule(todayRequest(hour: 21, minute: 0))]
        )

        // Act

        await sut.syncToday(
            hasCompletedHousework: true,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        let actual = await store.snapshot()
        #expect(actual == expected)
    }

    @Test("今日完了した家事が無ければ、完了日の記録と今日の予約を取り消す")
    func syncToday_noCompletedHousework_cancelsTodayReminder() async {
        // Arrange

        let store = ReminderClientStore(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-25"
        )
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = ReminderClientSnapshot(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedDayIdentifier: nil,
            entries: [.cancel("dailyCompletionReminder-2026-9-25")]
        )

        // Act

        await sut.syncToday(
            hasCompletedHousework: false,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        let actual = await store.snapshot()
        #expect(actual == expected)
    }

    @Test("通知が無効なら、完了日は記録するが予約はせず取り消す")
    func syncToday_disabled_recordsCompletedDayAndCancels() async {
        // Arrange

        let store = ReminderClientStore(setting: .init(isEnabled: false, hour: 21, minute: 0))
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = ReminderClientSnapshot(
            setting: .init(isEnabled: false, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-25",
            entries: [.cancel("dailyCompletionReminder-2026-9-25")]
        )

        // Act

        await sut.syncToday(
            hasCompletedHousework: true,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        let actual = await store.snapshot()
        #expect(actual == expected)
    }

}

// MARK: - handleCompleted

extension DailyCompletionReminderUseCaseTest.HandleCompletedCase {

    @Test("今日の家事が完了したら、完了日を記録して今日の通知を予約する")
    func handleCompleted_todayHousework_schedulesTodayReminder() async {
        // Arrange

        let store = ReminderClientStore(setting: .init(isEnabled: true, hour: 21, minute: 0))
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = ReminderClientSnapshot(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-25",
            entries: [.schedule(todayRequest(hour: 21, minute: 0))]
        )

        // Act

        await sut.handleCompleted(
            .init(houseworkDate: .previewDate(year: 2026, month: 9, day: 25)),
            trigger: .notificationServiceExtension,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        let actual = await store.snapshot()
        #expect(actual == expected)
    }

    @Test("今日以外の家事が完了しても、何もしない")
    func handleCompleted_otherDayHousework_doesNothing() async {
        // Arrange

        let store = ReminderClientStore(setting: .init(isEnabled: true, hour: 21, minute: 0))
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = ReminderClientSnapshot(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedDayIdentifier: nil,
            entries: []
        )

        // Act

        await sut.handleCompleted(
            .init(houseworkDate: .previewDate(year: 2026, month: 9, day: 24)),
            trigger: .notificationServiceExtension,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        let actual = await store.snapshot()
        #expect(actual == expected)
    }

}

// MARK: - updateSetting

extension DailyCompletionReminderUseCaseTest.UpdateSettingCase {

    @Test("今日すでに完了した家事があれば、新しい時刻で予約し直す")
    func updateSetting_completedToday_reschedulesWithNewTime() async {
        // Arrange

        let store = ReminderClientStore(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-25"
        )
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = ReminderClientSnapshot(
            setting: .init(isEnabled: true, hour: 22, minute: 15),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-25",
            entries: [
                .saveSetting(.init(isEnabled: true, hour: 22, minute: 15)),
                .schedule(todayRequest(hour: 22, minute: 15)),
            ]
        )

        // Act

        await sut.updateSetting(
            .init(isEnabled: true, hour: 22, minute: 15),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        let actual = await store.snapshot()
        #expect(actual == expected)
    }

    @Test("今日すでに完了した家事があるときに通知を無効にすると、今日の予約を取り消す")
    func updateSetting_completedTodayAndDisabled_cancelsTodayReminder() async {
        // Arrange

        let store = ReminderClientStore(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-25"
        )
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = ReminderClientSnapshot(
            setting: .init(isEnabled: false, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-25",
            entries: [
                .saveSetting(.init(isEnabled: false, hour: 21, minute: 0)),
                .cancel("dailyCompletionReminder-2026-9-25"),
            ]
        )

        // Act

        await sut.updateSetting(
            .init(isEnabled: false, hour: 21, minute: 0),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        let actual = await store.snapshot()
        #expect(actual == expected)
    }

    @Test("今日の完了が記録されていなければ、設定の保存だけを行う")
    func updateSetting_notCompletedToday_onlySavesSetting() async {
        // Arrange

        let store = ReminderClientStore(
            setting: .init(isEnabled: false, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-24"
        )
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = ReminderClientSnapshot(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-24",
            entries: [.saveSetting(.init(isEnabled: true, hour: 21, minute: 0))]
        )

        // Act

        await sut.updateSetting(
            .init(isEnabled: true, hour: 21, minute: 0),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        let actual = await store.snapshot()
        #expect(actual == expected)
    }

}

// MARK: - 1日1回の制限

extension DailyCompletionReminderUseCaseTest.DailyLimitCase {

    @Test("1日1回の制限を外している場合は、予約のたびに別の識別子で、きっかけと時刻を本文に載せて通知を積む")
    func handleCompleted_dailyLimitDisabled_schedulesWithPerScheduleIdentifier() async {
        // Arrange

        let store = ReminderClientStore(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            isDailyLimitDisabled: true
        )
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = ReminderClientSnapshot(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedDayIdentifier: "dailyCompletionReminder-2026-9-25",
            entries: [
                .schedule(todayRequest(
                    hour: 21,
                    minute: 0,
                    identifier: "dailyCompletionReminder-2026-9-25#1790298000",
                    debugNote: "[DEBUG] 通知拡張 / 10:00予約"
                )),
                .schedule(todayRequest(
                    hour: 21,
                    minute: 0,
                    identifier: "dailyCompletionReminder-2026-9-25#1790298060",
                    debugNote: "[DEBUG] 通知拡張 / 10:01予約"
                )),
            ]
        )

        // Act

        await sut.handleCompleted(
            .init(houseworkDate: .previewDate(year: 2026, month: 9, day: 25)),
            trigger: .notificationServiceExtension,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )
        await sut.handleCompleted(
            .init(houseworkDate: .previewDate(year: 2026, month: 9, day: 25)),
            trigger: .notificationServiceExtension,
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10, minute: 1),
            calendar: .japanese
        )

        // Assert

        let actual = await store.snapshot()
        #expect(actual == expected)
    }

    @Test("1日1回の制限を外すかを保存し、読み出せる")
    func updateIsDailyLimitDisabled_savesValue() async {
        // Arrange

        let store = ReminderClientStore(setting: .init(isEnabled: true, hour: 21, minute: 0))
        let sut = DailyCompletionReminderUseCase(client: store.client)

        // Act

        await sut.updateIsDailyLimitDisabled(true)

        // Assert

        let actual = await sut.loadIsDailyLimitDisabled()
        #expect(actual == true)
    }

}

// MARK: - notifyCompletedIfNeeded

extension DailyCompletionReminderUseCaseTest.NotifyCompletedCase {

    @Test("今日の家事の完了を今日まだ送っていなければ、完了通知を送って送信日を記録する")
    func notifyCompletedIfNeeded_notSentToday_sendsAndRecords() async throws {
        // Arrange

        let store = ReminderClientStore(setting: .init(isEnabled: true, hour: 21, minute: 0))
        let recorder = SentSignalRecorder()
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = NotifyCompletedResult(
            sent: [.init(houseworkDate: .previewDate(year: 2026, month: 9, day: 25))],
            sentDayIdentifier: "dailyCompletionReminder-2026-9-25"
        )

        // Act

        try await sut.notifyCompletedIfNeeded(
            houseworkDate: .previewDate(year: 2026, month: 9, day: 25),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        ) { await recorder.append($0) }

        // Assert

        let actual = await NotifyCompletedResult(
            sent: recorder.sent,
            sentDayIdentifier: store.completedSignalSentDayIdentifier
        )
        #expect(actual == expected)
    }

    @Test("今日すでに送っていれば、完了通知を送らない")
    func notifyCompletedIfNeeded_alreadySentToday_doesNotSend() async throws {
        // Arrange

        let store = ReminderClientStore(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedSignalSentDayIdentifier: "dailyCompletionReminder-2026-9-25"
        )
        let recorder = SentSignalRecorder()
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = NotifyCompletedResult(
            sent: [],
            sentDayIdentifier: "dailyCompletionReminder-2026-9-25"
        )

        // Act

        try await sut.notifyCompletedIfNeeded(
            houseworkDate: .previewDate(year: 2026, month: 9, day: 25),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        ) { await recorder.append($0) }

        // Assert

        let actual = await NotifyCompletedResult(
            sent: recorder.sent,
            sentDayIdentifier: store.completedSignalSentDayIdentifier
        )
        #expect(actual == expected)
    }

    @Test("前日に送っていても、今日まだ送っていなければ完了通知を送る")
    func notifyCompletedIfNeeded_sentYesterday_sends() async throws {
        // Arrange

        let store = ReminderClientStore(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            completedSignalSentDayIdentifier: "dailyCompletionReminder-2026-9-24"
        )
        let recorder = SentSignalRecorder()
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = NotifyCompletedResult(
            sent: [.init(houseworkDate: .previewDate(year: 2026, month: 9, day: 25))],
            sentDayIdentifier: "dailyCompletionReminder-2026-9-25"
        )

        // Act

        try await sut.notifyCompletedIfNeeded(
            houseworkDate: .previewDate(year: 2026, month: 9, day: 25),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        ) { await recorder.append($0) }

        // Assert

        let actual = await NotifyCompletedResult(
            sent: recorder.sent,
            sentDayIdentifier: store.completedSignalSentDayIdentifier
        )
        #expect(actual == expected)
    }

    @Test("今日以外の家事の完了では、完了通知を送らない")
    func notifyCompletedIfNeeded_notToday_doesNotSend() async throws {
        // Arrange

        let store = ReminderClientStore(setting: .init(isEnabled: true, hour: 21, minute: 0))
        let recorder = SentSignalRecorder()
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = NotifyCompletedResult(sent: [], sentDayIdentifier: nil)

        // Act

        try await sut.notifyCompletedIfNeeded(
            houseworkDate: .previewDate(year: 2026, month: 9, day: 24),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        ) { await recorder.append($0) }

        // Assert

        let actual = await NotifyCompletedResult(
            sent: recorder.sent,
            sentDayIdentifier: store.completedSignalSentDayIdentifier
        )
        #expect(actual == expected)
    }

    @Test("送信に失敗した場合は送信日を記録せず、エラーを返す")
    func notifyCompletedIfNeeded_sendFailed_doesNotRecord() async {
        // Arrange

        let store = ReminderClientStore(setting: .init(isEnabled: true, hour: 21, minute: 0))
        let sut = DailyCompletionReminderUseCase(client: store.client)

        // Act

        await #expect(throws: SendSignalError.self) {
            try await sut.notifyCompletedIfNeeded(
                houseworkDate: .previewDate(year: 2026, month: 9, day: 25),
                now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
                calendar: .japanese
            ) { _ in throw SendSignalError() }
        }

        // Assert

        let actual = await store.completedSignalSentDayIdentifier
        #expect(actual == nil)
    }

    @Test("1日1回の制限を外している場合は、今日すでに送っていても完了通知を送る")
    func notifyCompletedIfNeeded_dailyLimitDisabled_sendsEveryTime() async throws {
        // Arrange

        let store = ReminderClientStore(
            setting: .init(isEnabled: true, hour: 21, minute: 0),
            isDailyLimitDisabled: true,
            completedSignalSentDayIdentifier: "dailyCompletionReminder-2026-9-25"
        )
        let recorder = SentSignalRecorder()
        let sut = DailyCompletionReminderUseCase(client: store.client)
        let expected = NotifyCompletedResult(
            sent: [.init(houseworkDate: .previewDate(year: 2026, month: 9, day: 25))],
            sentDayIdentifier: "dailyCompletionReminder-2026-9-25"
        )

        // Act

        try await sut.notifyCompletedIfNeeded(
            houseworkDate: .previewDate(year: 2026, month: 9, day: 25),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        ) { await recorder.append($0) }

        // Assert

        let actual = await NotifyCompletedResult(
            sent: recorder.sent,
            sentDayIdentifier: store.completedSignalSentDayIdentifier
        )
        #expect(actual == expected)
    }

}

// MARK: - Helpers

private func todayRequest(
    hour: Int,
    minute: Int,
    identifier: String = "dailyCompletionReminder-2026-9-25",
    debugNote: String? = nil
) -> DailyCompletionReminderRequest {
    let body = "今日完了した家事があります。ふりかえって、感謝を伝え合いましょう"
    return .init(
        identifier: identifier,
        fireDateComponents: DateComponents(year: 2026, month: 9, day: 25, hour: hour, minute: minute),
        title: "今日もおつかれさまでした",
        body: debugNote.map { body + "\n" + $0 } ?? body
    )
}

private struct ReminderClientSnapshot: Equatable {

    let setting: DailyCompletionReminderSetting
    let completedDayIdentifier: String?
    let entries: [ReminderClientStore.Entry]

}

private struct NotifyCompletedResult: Equatable {

    let sent: [HouseworkCompletedNotificationData]
    let sentDayIdentifier: String?

}

private struct SendSignalError: Error {}

/// 送った完了通知の内容を記録するフェイク
private actor SentSignalRecorder {

    private(set) var sent: [HouseworkCompletedNotificationData] = []

    func append(_ data: HouseworkCompletedNotificationData) {
        sent.append(data)
    }

}

/// 設定・完了日の保存先と、予約・取消の呼び出し履歴を持つフェイク
private actor ReminderClientStore {

    enum Entry: Equatable {

        case saveSetting(DailyCompletionReminderSetting)
        case schedule(DailyCompletionReminderRequest)
        case cancel(String)

    }

    private var setting: DailyCompletionReminderSetting
    private var completedDayIdentifier: String?
    private var isDailyLimitDisabled: Bool
    private(set) var completedSignalSentDayIdentifier: String?
    private var entries: [Entry] = []

    init(
        setting: DailyCompletionReminderSetting,
        completedDayIdentifier: String? = nil,
        isDailyLimitDisabled: Bool = false,
        completedSignalSentDayIdentifier: String? = nil
    ) {
        self.setting = setting
        self.completedDayIdentifier = completedDayIdentifier
        self.isDailyLimitDisabled = isDailyLimitDisabled
        self.completedSignalSentDayIdentifier = completedSignalSentDayIdentifier
    }

    nonisolated var client: DailyCompletionReminderClient {
        .init(
            loadSetting: { await self.setting },
            saveSetting: { await self.saveSetting($0) },
            loadCompletedDayIdentifier: { await self.completedDayIdentifier },
            saveCompletedDayIdentifier: { await self.saveCompletedDayIdentifier($0) },
            loadCompletedSignalSentDayIdentifier: { await self.completedSignalSentDayIdentifier },
            saveCompletedSignalSentDayIdentifier: { await self.saveCompletedSignalSentDayIdentifier($0) },
            loadIsDailyLimitDisabled: { await self.isDailyLimitDisabled },
            saveIsDailyLimitDisabled: { await self.saveIsDailyLimitDisabled($0) },
            schedule: { await self.append(.schedule($0)) },
            cancel: { await self.append(.cancel($0)) }
        )
    }

    func snapshot() -> ReminderClientSnapshot {
        .init(setting: setting, completedDayIdentifier: completedDayIdentifier, entries: entries)
    }

    private func saveSetting(_ setting: DailyCompletionReminderSetting) {
        self.setting = setting
        entries.append(.saveSetting(setting))
    }

    private func saveCompletedDayIdentifier(_ identifier: String?) {
        completedDayIdentifier = identifier
    }

    private func saveCompletedSignalSentDayIdentifier(_ identifier: String) {
        completedSignalSentDayIdentifier = identifier
    }

    private func saveIsDailyLimitDisabled(_ isDisabled: Bool) {
        isDailyLimitDisabled = isDisabled
    }

    private func append(_ entry: Entry) {
        entries.append(entry)
    }

}
