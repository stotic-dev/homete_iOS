//
//  SettingNotificationScreen.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// 設定画面の「通知設定」から開く画面
///
/// 通知が許可されている場合は、毎日のふりかえり通知の設定を表示する。
/// 許可されていない場合は、これまで通り通知の権限を案内する。
struct SettingNotificationScreen: View {

    @Environment(\.scenePhase) var scenePhase
    @Environment(\.appDependencies.notificationPermissionClient) var notificationPermissionClient

    /// 通知が許可されているか。確認が終わるまでは`nil`
    @State var isAuthorized: Bool?

    var body: some View {
        content
            .task {
                await refreshAuthorization()
            }
            .onChange(of: scenePhase) { _, newPhase in
                // 案内から設定アプリで通知を許可して戻ってきた場合に、設定内容の表示へ切り替える
                guard newPhase == .active else { return }
                Task {
                    await refreshAuthorization()
                }
            }
    }

}

// MARK: - UI定義

private extension SettingNotificationScreen {

    @ViewBuilder
    var content: some View {
        switch isAuthorized {
        case .none:
            // 権限の確認は一瞬で終わるため、ローディング表示は出さずに空けておく
            Color.clear

        case .some(true):
            DailyCompletionReminderSettingScreen()

        case .some(false):
            SettingNotificationPermissionGuideView {
                isAuthorized = true
            }
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension SettingNotificationScreen {

    func refreshAuthorization() async {
        isAuthorized = await notificationPermissionClient.isAuthorized()
    }

}
