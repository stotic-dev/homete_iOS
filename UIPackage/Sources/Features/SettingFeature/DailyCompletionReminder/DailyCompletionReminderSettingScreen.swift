//
//  DailyCompletionReminderSettingScreen.swift
//  LocalPackage
//

import HometeDomainUI
import HometeDomain
import HometeUI
import SettingFeatureUI
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
    /// 直前のお知らせの通知の切り替え
    /// - Note: 素早く切り替えると、保存と購読の切り替えが前後して設定と購読が食い違うため、前の切り替えを待ってから次を行う
    @State var announcementNotificationUpdateTask: Task<Void, Never>?

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
                changedAnnouncementNotificationEnabled(isEnabled)
            }
        )
        .task {
            await loadSetting()
        }
        .trackScreenView(.settingNotification)
    }

}

// MARK: - プレゼンテーションロジック

private extension DailyCompletionReminderSettingScreen {

    func loadSetting() async {
        setting = await dailyCompletionReminderUseCase.loadSetting()
        isAnnouncementNotificationEnabled = await announcementTopicUseCase.isEnabled()
    }

    func changedAnnouncementNotificationEnabled(_ isEnabled: Bool) {
        isAnnouncementNotificationEnabled = isEnabled
        let previousTask = announcementNotificationUpdateTask
        announcementNotificationUpdateTask = Task {
            await previousTask?.value
            await announcementTopicUseCase.update(isEnabled: isEnabled)
        }
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
