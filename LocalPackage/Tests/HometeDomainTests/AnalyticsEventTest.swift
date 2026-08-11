//
//  AnalyticsEventTest.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

struct AnalyticsEventTest {

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

}
