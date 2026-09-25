//
//  DailyCompletionReminderSettingView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// ふりかえり通知の設定画面（依存の取得と状態の保持を担う）
struct DailyCompletionReminderSettingScreen: View {

    @Environment(\.calendar) var calendar
    @Environment(\.appDependencies.dailyCompletionReminderUseCase) var dailyCompletionReminderUseCase
    @Environment(\.appDependencies.notificationPermissionClient) var notificationPermissionClient

    @State var setting: DailyCompletionReminderSetting?
    @State var isNotificationDenied = false

    var body: some View {
        DailyCompletionReminderSettingView(
            setting: setting ?? .initial,
            isNotificationDenied: isNotificationDenied,
            calendar: calendar,
            onChangeEnabled: { isEnabled in
                Task {
                    await changedEnabled(isEnabled)
                }
            },
            onChangeTime: { hour, minute in
                Task {
                    await changedTime(hour: hour, minute: minute)
                }
            }
        )
        .task {
            await loadSetting()
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension DailyCompletionReminderSettingScreen {

    func loadSetting() async {
        setting = await dailyCompletionReminderUseCase.loadSetting()
    }

    func changedEnabled(_ isEnabled: Bool) async {
        let current = setting ?? .initial
        let updated = current.updateIsEnabled(isEnabled)
        setting = updated
        // 権限ダイアログの応答を待つ間にトグルを戻されても、保存順が画面の操作順とずれないよう先に保存する
        await dailyCompletionReminderUseCase.updateSetting(updated, now: .now, calendar: calendar)

        guard isEnabled else {
            isNotificationDenied = false
            return
        }
        // 権限が決定済みの場合はダイアログを出さずに現在の許可状態が返る
        let isGranted = await notificationPermissionClient.requestAuthorization()
        // 応答を待つ間に無効へ戻された場合は、案内を出さない
        isNotificationDenied = !isGranted && setting?.isEnabled == true
    }

    func changedTime(hour: Int, minute: Int) async {
        let current = setting ?? .initial
        let updated = current.updateTime(hour: hour, minute: minute)
        setting = updated
        await dailyCompletionReminderUseCase.updateSetting(updated, now: .now, calendar: calendar)
    }

}

/// ふりかえり通知の設定画面の表示
struct DailyCompletionReminderSettingView: View {

    let setting: DailyCompletionReminderSetting
    let isNotificationDenied: Bool
    let calendar: Calendar
    let onChangeEnabled: (Bool) -> Void
    let onChangeTime: (_ hour: Int, _ minute: Int) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space24) {
                Text(
                    "今日完了した家事がある日に、決めた時刻にお知らせします。1日の終わりに、家事をふりかえって感謝を伝え合えます。"
                )
                    .font(with: .body)
                    .foregroundStyle(.onSurface)
                settingCard
                if isNotificationDenied {
                    Text(
                        "通知がオフになっているため、お知らせが届きません。設定の「通知設定」から通知を許可してください。"
                    )
                        .font(with: .caption)
                        .foregroundStyle(.onSubSurface)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.space16)
        }
        .navigationTitle("ふりかえり通知")
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .trackScreenView(.settingDailyCompletionReminder)
    }

}

// MARK: - UI定義

private extension DailyCompletionReminderSettingView {

    var settingCard: some View {
        VStack(spacing: .space8) {
            Toggle(isOn: enabledBinding) {
                Text("お知らせを受け取る")
                    .font(with: .headLineS)
                    .foregroundStyle(.onSurface)
            }
            if setting.isEnabled {
                Divider()
                DatePicker(selection: timeBinding, displayedComponents: .hourAndMinute) {
                    Text("お知らせする時刻")
                        .font(with: .headLineS)
                        .foregroundStyle(.onSurface)
                }
            }
        }
        .padding(.space16)
        .background(.subSurface)
        .cornerRadius(.radius16)
    }

    var enabledBinding: Binding<Bool> {
        .init {
            setting.isEnabled
        } set: { isEnabled in
            onChangeEnabled(isEnabled)
        }
    }

    /// DatePickerは日時で扱うため、設定の時・分を今日の日時に載せて受け渡す
    var timeBinding: Binding<Date> {
        .init {
            calendar.date(bySettingHour: setting.hour, minute: setting.minute, second: .zero, of: .now) ?? .now
        } set: { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            onChangeTime(components.hour ?? setting.hour, components.minute ?? setting.minute)
        }
    }

}

#if DEBUG
#Preview("DailyCompletionReminderSettingView_無効") {
    NavigationStack {
        DailyCompletionReminderSettingView(
            setting: .init(isEnabled: false, hour: 21, minute: 0),
            isNotificationDenied: false,
            calendar: .japanese,
            onChangeEnabled: { _ in },
            onChangeTime: { _, _ in }
        )
    }
}

#Preview("DailyCompletionReminderSettingView_有効") {
    NavigationStack {
        DailyCompletionReminderSettingView(
            setting: .init(isEnabled: true, hour: 21, minute: 30),
            isNotificationDenied: false,
            calendar: .japanese,
            onChangeEnabled: { _ in },
            onChangeTime: { _, _ in }
        )
    }
}

#Preview("DailyCompletionReminderSettingView_通知オフ") {
    NavigationStack {
        DailyCompletionReminderSettingView(
            setting: .init(isEnabled: true, hour: 21, minute: 30),
            isNotificationDenied: true,
            calendar: .japanese,
            onChangeEnabled: { _ in },
            onChangeTime: { _, _ in }
        )
    }
}
#endif
