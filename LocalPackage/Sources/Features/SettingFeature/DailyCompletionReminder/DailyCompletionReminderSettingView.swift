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
    @Environment(\.appDependencies.announcementTopicUseCase) var announcementTopicUseCase

    @State var setting: DailyCompletionReminderSetting?
    /// お知らせの通知を受け取る設定か。読み込むまでは`nil`
    @State var isAnnouncementNotificationEnabled: Bool?

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
            },
            // 未設定の端末は受け取る設定になるため、読み込むまではオンで出す
            isAnnouncementNotificationEnabled: isAnnouncementNotificationEnabled ?? true,
            onChangeAnnouncementNotificationEnabled: { isEnabled in
                Task {
                    await changedAnnouncementNotificationEnabled(isEnabled)
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
        isAnnouncementNotificationEnabled = await announcementTopicUseCase.isEnabled()
    }

    func changedAnnouncementNotificationEnabled(_ isEnabled: Bool) async {
        isAnnouncementNotificationEnabled = isEnabled
        await announcementTopicUseCase.update(isEnabled: isEnabled)
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
    let isAnnouncementNotificationEnabled: Bool
    let onChangeAnnouncementNotificationEnabled: (Bool) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space24) {
                VStack(alignment: .leading, spacing: .space8) {
                    sectionHeader
                    settingCard
                    Text(
                        "今日完了した家事がある日に、決めた時刻にお知らせします。1日の終わりに、家事をふりかえって感謝を伝え合えます。",
                        bundle: #bundle
                    )
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
                    .padding(.horizontal, .space16)
                }
                announcementSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.space16)
        }
        // 純正の設定アプリと同じく、セクションのカードと画面の背景の色を分けて境目を見せる
        .background(.backgroundScreen)
        .navigationTitle(.localized("通知設定"))
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .trackScreenView(.settingNotification)
    }

}

// MARK: - UI定義

private extension DailyCompletionReminderSettingView {

    var sectionHeader: some View {
        Text("毎日の家事のふりかえり", bundle: #bundle)
            .font(with: .boldCaption)
            .foregroundStyle(.textSecondary)
            .padding(.horizontal, .space16)
    }

    var settingCard: some View {
        VStack(spacing: .space8) {
            Toggle(isOn: enabledBinding) {
                Text("ふりかえりの通知を受け取る", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
            }
            if setting.isEnabled {
                Divider()
                DatePicker(selection: timeBinding, displayedComponents: .hourAndMinute) {
                    Text("毎日の通知時刻", bundle: #bundle)
                        .font(with: .body)
                        .foregroundStyle(.textPrimary)
                }
                // 時・分の変換に使うcalendarと表示のタイムゾーンを揃え、設定した時刻がずれて表示されないようにする
                .environment(\.calendar, calendar)
                .environment(\.timeZone, calendar.timeZone)
            }
        }
        .padding(.space16)
        .background(.backgroundCard)
        .cornerRadius(.radius20)
    }

    var announcementSection: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("お知らせ", bundle: #bundle)
                .font(with: .boldCaption)
                .foregroundStyle(.textSecondary)
                .padding(.horizontal, .space16)
            Toggle(isOn: announcementEnabledBinding) {
                Text("運営からのお知らせを受け取る", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
            }
            .padding(.space16)
            .background(.backgroundCard)
            .cornerRadius(.radius20)
            Text("メンテナンスや新しい機能など、大事なお知らせを通知でお届けします。オフにしても、ダッシュボードのベルから読めます。", bundle: #bundle)
                .font(with: .caption)
                .foregroundStyle(.textSecondary)
                .padding(.horizontal, .space16)
        }
    }

    var announcementEnabledBinding: Binding<Bool> {
        .init {
            isAnnouncementNotificationEnabled
        } set: { isEnabled in
            onChangeAnnouncementNotificationEnabled(isEnabled)
        }
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
            onChangeTime: { _, _ in },
            isAnnouncementNotificationEnabled: true,
            onChangeAnnouncementNotificationEnabled: { _ in }
        )
    }
}

#Preview("DailyCompletionReminderSettingView_有効") {
    NavigationStack {
        DailyCompletionReminderSettingView(
            setting: .init(isEnabled: true, hour: 21, minute: 30),
            calendar: .japanese,
            onChangeEnabled: { _ in },
            onChangeTime: { _, _ in },
            isAnnouncementNotificationEnabled: true,
            onChangeAnnouncementNotificationEnabled: { _ in }
        )
    }
}

#Preview("DailyCompletionReminderSettingView_お知らせオフ") {
    NavigationStack {
        DailyCompletionReminderSettingView(
            setting: .init(isEnabled: true, hour: 21, minute: 30),
            calendar: .japanese,
            onChangeEnabled: { _ in },
            onChangeTime: { _, _ in },
            isAnnouncementNotificationEnabled: false,
            onChangeAnnouncementNotificationEnabled: { _ in }
        )
    }
}
#endif
