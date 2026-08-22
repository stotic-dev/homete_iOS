//
//  OnboardingNotificationPermissionGuideView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// オンボーディングでプッシュ通知の役割を説明し、権限リクエストのダイアログを出す画面
struct OnboardingNotificationPermissionGuideView: View {

    @Environment(\.appDependencies.notificationPermissionUseCase) var notificationPermissionUseCase
    @Environment(\.appDependencies.analyticsClient) var analyticsClient

    /// この画面での操作が終わり、オンボーディングを完了するときに呼ばれる
    let onNext: () -> Void

    var body: some View {
        NotificationPermissionGuideView {
            Task {
                await tappedSkipButton()
            }
        } onTapEnableNotificationButton: {
            Task {
                await tappedEnableNotificationButton()
            }
        }
    }

}

// MARK: プレゼンテーションロジック

private extension OnboardingNotificationPermissionGuideView {

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
