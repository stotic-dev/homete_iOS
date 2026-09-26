//
//  DailyCompletionReminderSettingView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 通知が許可されているときの通知設定画面（依存の取得と状態の保持を担う）
/// - Note: 通知の権限がある場合にだけ`SettingNotificationScreen`から表示される
struct DailyCompletionReminderSettingScreen: View {

    @Environment(\.calendar) var calendar
    @Environment(\.appDependencies.dailyCompletionReminderUseCase) var dailyCompletionReminderUseCase

    @State var setting: DailyCompletionReminderSetting?

    var body: some View {
        DailyCompletionReminderSettingView(
            setting: setting ?? .initial,
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
        await dailyCompletionReminderUseCase.updateSetting(updated, now: .now, calendar: calendar)
    }

    func changedTime(hour: Int, minute: Int) async {
        let current = setting ?? .initial
        let updated = current.updateTime(hour: hour, minute: minute)
        setting = updated
        await dailyCompletionReminderUseCase.updateSetting(updated, now: .now, calendar: calendar)
    }

}

/// 通知が許可されているときの通知設定画面の表示
struct DailyCompletionReminderSettingView: View {

    let setting: DailyCompletionReminderSetting
    let calendar: Calendar
    let onChangeEnabled: (Bool) -> Void
    let onChangeTime: (_ hour: Int, _ minute: Int) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space8) {
                sectionHeader
                settingCard
                Text(
                    "今日完了した家事がある日に、決めた時刻にお知らせします。1日の終わりに、家事をふりかえって感謝を伝え合えます。"
                )
                    .font(with: .caption)
                    .foregroundStyle(.onSubSurface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.space16)
        }
        .navigationTitle("通知設定")
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .trackScreenView(.settingNotification)
    }

}

// MARK: - UI定義

private extension DailyCompletionReminderSettingView {

    var sectionHeader: some View {
        HStack(spacing: .space8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.onSurface)
            Text("毎日の家事のふりかえり")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            Spacer()
        }
    }

    var settingCard: some View {
        VStack(spacing: .space8) {
            Toggle(isOn: enabledBinding) {
                Text("ふりかえりの通知を受け取る")
                    .font(with: .headLineS)
                    .foregroundStyle(.onSurface)
            }
            if setting.isEnabled {
                Divider()
                DatePicker(selection: timeBinding, displayedComponents: .hourAndMinute) {
                    Text("毎日の通知時刻")
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
            calendar: .japanese,
            onChangeEnabled: { _ in },
            onChangeTime: { _, _ in }
        )
    }
}
#endif
