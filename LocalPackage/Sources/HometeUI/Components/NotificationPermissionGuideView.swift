//
//  NotificationPermissionGuideView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/08/22.
//

import HometeDomain
import SwiftUI

/// プッシュ通知の役割を説明し、通知設定の導線を提供するUI
public struct NotificationPermissionGuideView: View {

    @Environment(\.appDependencies.notificationPermissionUseCase) var notificationPermissionUseCase
    @Environment(\.appDependencies.analyticsClient) var analyticsClient

    /// スキップボタンタップ時の処理
    let onTapSkipButton: () -> Void
    /// 通知設定タップ時の処理
    let onTapEnableNotificationButton: () -> Void

    public init(
        onTapSkipButton: @escaping () -> Void,
        onTapEnableNotificationButton: @escaping () -> Void
    ) {
        self.onTapSkipButton = onTapSkipButton
        self.onTapEnableNotificationButton = onTapEnableNotificationButton
    }

    public var body: some View {
        VStack(spacing: .space32) {
            VStack(spacing: .space16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.primary3)
                Text("通知を受け取りませんか？")
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                Text("パートナーが家事を完了したときにお知らせします。\nお互いの家事に気づけると、「ありがとう」を伝えやすくなります。")
                    .font(with: .body)
                    .foregroundStyle(.primary2)
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: .space24)
            VStack(spacing: .space16) {
                Button {
                    onTapEnableNotificationButton()
                } label: {
                    Text("通知を受け取る")
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .subPrimaryButtonStyle()
                Button("あとで設定する") {
                    onTapSkipButton()
                }
                .font(with: .body)
                .foregroundStyle(.primary2)
            }
            Spacer()
                .frame(height: .space24)
        }
        .padding(.horizontal, .space16)
        .padding(.top, .space48)
        .frame(maxHeight: .infinity, alignment: .top)
    }

}

#Preview("NotificationPermissionGuideView") {
    NotificationPermissionGuideView(
        onTapSkipButton: {},
        onTapEnableNotificationButton: {}
    )
}
