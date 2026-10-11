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
                    .foregroundStyle(.iconDecorative)
                Text("通知を受け取りませんか？", bundle: #bundle)
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                Text(
                    "パートナーが家事を終えたときや、メッセージ付きの「ありがとう」が届いたときにお知らせします。\n家事が終わった日の夜には、ふりかえりの通知も届きます。時刻は設定で変えられます。",
                    bundle: #bundle
                )
                .font(with: .body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
            }
            Spacer(minLength: .space24)
            VStack(spacing: .space16) {
                Button {
                    onTapEnableNotificationButton()
                } label: {
                    Text("通知を受け取る", bundle: #bundle)
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
                Button(.localized("あとで設定する")) {
                    onTapSkipButton()
                }
                .font(with: .body)
                .foregroundStyle(.textSecondary)
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
