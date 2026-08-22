//
//  AnalyticsEventTest.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

struct AnalyticsEventTest {

    @Test(
        "オンボーディング中の行動を、step/action/resultのパラメータを持つonboardingイベントに変換する",
        arguments: [
            (
                OnboardingAnalyticsAction.premiumIntroductionShown,
                ["step": "premium_introduction", "action": "shown"]
            ),
            (
                OnboardingAnalyticsAction.paywallShown,
                ["step": "premium_introduction", "action": "paywall_shown"]
            ),
            (
                OnboardingAnalyticsAction.paywallClosed(isPremium: true),
                ["step": "premium_introduction", "action": "paywall_closed", "result": "purchased"]
            ),
            (
                OnboardingAnalyticsAction.paywallClosed(isPremium: false),
                ["step": "premium_introduction", "action": "paywall_closed", "result": "not_purchased"]
            ),
            (
                OnboardingAnalyticsAction.premiumIntroductionSkipped,
                ["step": "premium_introduction", "action": "skipped"]
            ),
            (
                OnboardingAnalyticsAction.notificationPermissionRequested(isGranted: true),
                ["step": "notification_permission", "action": "permission_requested", "result": "granted"]
            ),
            (
                OnboardingAnalyticsAction.notificationPermissionRequested(isGranted: false),
                ["step": "notification_permission", "action": "permission_requested", "result": "denied"]
            ),
            (
                OnboardingAnalyticsAction.notificationPermissionSkipped,
                ["step": "notification_permission", "action": "skipped"]
            ),
        ]
    )
    func onboarding(action: OnboardingAnalyticsAction, expectedParameters: [String: String]) {
        let actual = AnalyticsEvent.onboarding(action)

        #expect(actual == AnalyticsEvent(name: "onboarding", parameters: expectedParameters))
    }

}
