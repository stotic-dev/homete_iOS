//
//  AnalyticsEventTest.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

struct AnalyticsEventTest {

    @Test("オンボーディングの特典説明画面表示イベントを生成する")
    func onboardingPremiumIntroductionShown() {
        let actual = AnalyticsEvent.onboardingPremiumIntroductionShown()

        #expect(actual == AnalyticsEvent(name: "onboarding_premium_introduction_shown", parameters: [:]))
    }

    @Test("オンボーディングの特典説明画面スキップイベントを生成する")
    func onboardingPremiumIntroductionSkipped() {
        let actual = AnalyticsEvent.onboardingPremiumIntroductionSkipped()

        #expect(actual == AnalyticsEvent(name: "onboarding_premium_introduction_skipped", parameters: [:]))
    }

    @Test("オンボーディングのPaywall表示イベントを生成する")
    func onboardingPaywallShown() {
        let actual = AnalyticsEvent.onboardingPaywallShown()

        #expect(actual == AnalyticsEvent(name: "onboarding_paywall_shown", parameters: [:]))
    }

    @Test(
        "オンボーディングのPaywallを閉じたイベントに、閉じた時点のプレミアム状態を含める",
        arguments: [true, false]
    )
    func onboardingPaywallClosed(isPremium: Bool) {
        let actual = AnalyticsEvent.onboardingPaywallClosed(isPremium: isPremium)

        #expect(actual == AnalyticsEvent(
            name: "onboarding_paywall_closed",
            parameters: ["isPremium": "\(isPremium)"]
        ))
    }

    @Test(
        "オンボーディングの通知権限リクエストイベントに、許可されたかどうかを含める",
        arguments: [true, false]
    )
    func onboardingNotificationPermissionRequested(isGranted: Bool) {
        let actual = AnalyticsEvent.onboardingNotificationPermissionRequested(isGranted: isGranted)

        #expect(actual == AnalyticsEvent(
            name: "onboarding_notification_permission_requested",
            parameters: ["isGranted": "\(isGranted)"]
        ))
    }

    @Test("オンボーディングの通知権限スキップイベントを生成する")
    func onboardingNotificationPermissionSkipped() {
        let actual = AnalyticsEvent.onboardingNotificationPermissionSkipped()

        #expect(actual == AnalyticsEvent(name: "onboarding_notification_permission_skipped", parameters: [:]))
    }

}
