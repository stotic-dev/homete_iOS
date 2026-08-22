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

    var body: some View {
        NotificationPermissionGuideView {
            dismiss()
        } onTapEnableNotificationButton: {
            Task {
                await tappedEnableNotificationButton()
            }
        }
    }

}

// - MARK: プレゼンテーションロジック

private extension SettingNotificationPermissionGuideView {

    func tappedEnableNotificationButton() async {
        if await notificationPermissionClient.isAuthorizationDetermined() {
            oepnURL(URL(string: UIApplication.openNotificationSettingsURLString)!)
        } else {
            _ = await notificationPermissionClient.requestAuthorization()
            dismiss()
        }
    }

}

#Preview {
    SettingNotificationPermissionGuideView()
}
