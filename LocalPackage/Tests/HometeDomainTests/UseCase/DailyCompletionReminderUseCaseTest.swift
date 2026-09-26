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

// MARK: - Helpers

private func todayRequest(hour: Int, minute: Int) -> DailyCompletionReminderRequest {
    .init(
        identifier: "dailyCompletionReminder-2026-9-25",
        fireDateComponents: DateComponents(year: 2026, month: 9, day: 25, hour: hour, minute: minute),
        title: "今日もおつかれさまでした",
        body: "今日完了した家事があります。ふりかえって、感謝を伝え合いましょう"
    )
}

private struct ReminderClientSnapshot: Equatable {

    let setting: DailyCompletionReminderSetting
    let completedDayIdentifier: String?
    let entries: [ReminderClientStore.Entry]

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
    private var entries: [Entry] = []

    init(setting: DailyCompletionReminderSetting, completedDayIdentifier: String? = nil) {
        self.setting = setting
        self.completedDayIdentifier = completedDayIdentifier
    }

    nonisolated var client: DailyCompletionReminderClient {
        .init(
            loadSetting: { await self.setting },
            saveSetting: { await self.saveSetting($0) },
            loadCompletedDayIdentifier: { await self.completedDayIdentifier },
            saveCompletedDayIdentifier: { await self.saveCompletedDayIdentifier($0) },
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

    private func append(_ entry: Entry) {
        entries.append(entry)
    }

}
