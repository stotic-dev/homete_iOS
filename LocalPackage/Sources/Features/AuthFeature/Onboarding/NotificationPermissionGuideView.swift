//
//  NotificationPermissionGuideView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// オンボーディングでプッシュ通知の役割を説明し、権限リクエストのダイアログを出す画面
struct NotificationPermissionGuideView: View {

    @Environment(\.appDependencies.notificationPermissionUseCase) var notificationPermissionUseCase
    @Environment(\.appDependencies.analyticsClient) var analyticsClient

    /// この画面での操作が終わり、オンボーディングを完了するときに呼ばれる
    let onNext: () -> Void

    var body: some View {
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
                    Task {
                        await tappedEnableNotificationButton()
                    }
                } label: {
                    Text("通知を受け取る")
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .subPrimaryButtonStyle()
                Button("あとで設定する") {
                    Task {
                        await tappedSkipButton()
                    }
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

// MARK: プレゼンテーションロジック

private extension NotificationPermissionGuideView {

    /// 権限が許可されたかどうかに関わらず、リクエストを終えたらオンボーディングを完了する
    func tappedEnableNotificationButton() async {
        let isGranted = await notificationPermissionUseCase.requestOnOnboarding()
        analyticsClient.log(.onboarding(.notificationPermissionRequested(isGranted: isGranted)))
        onNext()
    }

    /// スキップした直後にホームで再びダイアログが出ないよう、案内済みであることをUseCaseに記録してから次へ進む
    func tappedSkipButton() async {
        await notificationPermissionUseCase.skipOnOnboarding()
        analyticsClient.log(.onboarding(.notificationPermissionSkipped))
        onNext()
    }

}

#Preview("NotificationPermissionGuideView") {
    NotificationPermissionGuideView {}
}
