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

    @Test(
        "招待リンクに関する行動を、action/step/resultのパラメータを持つcohabitant_invitationイベントに変換する",
        arguments: [
            (
                CohabitantInvitationAnalyticsAction.issued(screen: .cohabitantRegistration, isSuccess: true),
                ["action": "issue", "step": "cohabitant_registration", "result": "success"]
            ),
            (
                CohabitantInvitationAnalyticsAction.issued(screen: .cohabitantRegistration, isSuccess: false),
                ["action": "issue", "step": "cohabitant_registration", "result": "failure"]
            ),
            (
                CohabitantInvitationAnalyticsAction.issued(screen: .setting, isSuccess: true),
                ["action": "issue", "step": "setting", "result": "success"]
            ),
            (
                CohabitantInvitationAnalyticsAction.issued(screen: .setting, isSuccess: false),
                ["action": "issue", "step": "setting", "result": "failure"]
            ),
            (
                CohabitantInvitationAnalyticsAction.linkOpened,
                ["action": "open"]
            ),
            (
                CohabitantInvitationAnalyticsAction.joinSucceeded,
                ["action": "join", "result": "success"]
            ),
            (
                CohabitantInvitationAnalyticsAction.joinFailed(.invalidLink),
                ["action": "join", "result": "invalid_link"]
            ),
            (
                CohabitantInvitationAnalyticsAction.joinFailed(.expired),
                ["action": "join", "result": "expired"]
            ),
            (
                CohabitantInvitationAnalyticsAction.joinFailed(.alreadyJoined),
                ["action": "join", "result": "already_joined"]
            ),
            (
                CohabitantInvitationAnalyticsAction.joinFailed(.unknown),
                ["action": "join", "result": "failure"]
            ),
        ]
    )
    func cohabitantInvitation(
        action: CohabitantInvitationAnalyticsAction,
        expectedParameters: [String: String]
    ) {
        let actual = AnalyticsEvent.cohabitantInvitation(action)

        #expect(actual == AnalyticsEvent(name: "cohabitant_invitation", parameters: expectedParameters))
    }

}
