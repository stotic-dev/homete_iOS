//
//  ImplNotificationGuideStateClient.swift
//

import Foundation
import HometeDomain

public extension NotificationGuideStateClient {

    static let liveValue: NotificationGuideStateClient = .init {
        UserDefaults.standard.bool(forKey: Self.hasGuidedOnOnboardingKey)
    } saveHasGuidedOnOnboarding: {
        UserDefaults.standard.set($0, forKey: Self.hasGuidedOnOnboardingKey)
    }

}

private extension NotificationGuideStateClient {

    /// 未設定時は`false`が返るため、初回起動は「案内していない」として扱われる
    static let hasGuidedOnOnboardingKey = "hasGuidedNotificationPermissionOnOnboarding"

}
