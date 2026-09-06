//
//  SettingNotificationPermissionGuideView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/08/22.
//

import HometeDomain
import HometeUI
import SwiftUI

struct SettingNotificationPermissionGuideView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var oepnURL
    @Environment(\.appDependencies.notificationPermissionClient) var notificationPermissionClient
    @Environment(\.appDependencies.analyticsClient) var analyticsClient

    var body: some View {
        NotificationPermissionGuideView {
            tappedSkipButton()
        } onTapEnableNotificationButton: {
            Task {
                await tappedEnableNotificationButton()
            }
        }
        .trackScreenView(.settingNotificationPermission)
    }

}

// - MARK: プレゼンテーションロジック

private extension SettingNotificationPermissionGuideView {

    func tappedEnableNotificationButton() async {
        if await notificationPermissionClient.isAuthorizationDetermined() {
            // 権限の可否はすでに決まっているため、可否の結果は送らずに設定Appへの案内のみ行う
            analyticsClient.log(.notificationPermission(.permissionRequested(step: .setting, isGranted: nil)))
            #if canImport(UIKit)
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                oepnURL(url)
            }
            #endif
        } else {
            let isGranted = await notificationPermissionClient.requestAuthorization()
            analyticsClient.log(.notificationPermission(.permissionRequested(step: .setting, isGranted: isGranted)))
            dismiss()
        }
    }

    func tappedSkipButton() {
        analyticsClient.log(.notificationPermission(.skipped(step: .setting)))
        dismiss()
    }

}

#Preview {
    SettingNotificationPermissionGuideView()
}
