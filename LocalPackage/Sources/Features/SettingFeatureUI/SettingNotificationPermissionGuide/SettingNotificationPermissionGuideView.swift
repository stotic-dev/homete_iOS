//
//  SettingNotificationPermissionGuideView.swift
//  homete
//

import HometeModel
import HometeUI
import SwiftUI

/// 設定から開く、通知の許可を案内する画面
/// - Note: 権限の確認と計測は`SettingNotificationPermissionGuideScreen`が受け持つ
public struct SettingNotificationPermissionGuideView: View {

    let onTapSkip: () -> Void
    let onTapEnableNotification: () -> Void

    public init(onTapSkip: @escaping () -> Void, onTapEnableNotification: @escaping () -> Void) {
        self.onTapSkip = onTapSkip
        self.onTapEnableNotification = onTapEnableNotification
    }

    public var body: some View {
        NotificationPermissionGuideView {
            onTapSkip()
        } onTapEnableNotificationButton: {
            onTapEnableNotification()
        }
    }

}

#Preview {
    SettingNotificationPermissionGuideView(onTapSkip: {}, onTapEnableNotification: {})
}
