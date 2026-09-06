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
        ]
    )
    func onboarding(action: OnboardingAnalyticsAction, expectedParameters: [String: String]) {
        let actual = AnalyticsEvent.onboarding(action)

        #expect(actual == AnalyticsEvent(name: "onboarding", parameters: expectedParameters))
    }

    @Test(
        "画面の表示を、screen_nameパラメータを持つscreen_viewイベントに変換する",
        arguments: AppScreen.allCases
    )
    func screenView(screen: AppScreen) {
        let actual = AnalyticsEvent.screenView(screen)

        #expect(actual == AnalyticsEvent(name: "screen_view", parameters: ["screen_name": screen.rawValue]))
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

    @Test(
        "家事に関する行動を、action/step/resultのパラメータを持つhouseworkイベントに変換する",
        arguments: [
            (
                HouseworkAnalyticsAction.register(step: .board, isSuccess: true),
                ["action": "register", "step": "board", "result": "success"]
            ),
            (
                HouseworkAnalyticsAction.register(step: .dashboard, isSuccess: false),
                ["action": "register", "step": "dashboard", "result": "failure"]
            ),
            (
                HouseworkAnalyticsAction.requestReview(step: .detail, isSuccess: true),
                ["action": "request_review", "step": "detail", "result": "success"]
            ),
            (
                HouseworkAnalyticsAction.requestReview(step: .board, isSuccess: false),
                ["action": "request_review", "step": "board", "result": "failure"]
            ),
            (
                HouseworkAnalyticsAction.approve(isSuccess: true),
                ["action": "approve", "step": "approval", "result": "success"]
            ),
            (
                HouseworkAnalyticsAction.approve(isSuccess: false),
                ["action": "approve", "step": "approval", "result": "failure"]
            ),
            (
                HouseworkAnalyticsAction.reject(isSuccess: true),
                ["action": "reject", "step": "approval", "result": "success"]
            ),
            (
                HouseworkAnalyticsAction.reject(isSuccess: false),
                ["action": "reject", "step": "approval", "result": "failure"]
            ),
            (
                HouseworkAnalyticsAction.returnIncomplete(step: .detail, isSuccess: true),
                ["action": "return_incomplete", "step": "detail", "result": "success"]
            ),
            (
                HouseworkAnalyticsAction.returnIncomplete(step: .dashboard, isSuccess: false),
                ["action": "return_incomplete", "step": "dashboard", "result": "failure"]
            ),
            (
                HouseworkAnalyticsAction.delete(step: .detail, isSuccess: true),
                ["action": "delete", "step": "detail", "result": "success"]
            ),
            (
                HouseworkAnalyticsAction.delete(step: .board, isSuccess: false),
                ["action": "delete", "step": "board", "result": "failure"]
            ),
        ]
    )
    func housework(action: HouseworkAnalyticsAction, expectedParameters: [String: String]) {
        let actual = AnalyticsEvent.housework(action)

        #expect(actual == AnalyticsEvent(name: "housework", parameters: expectedParameters))
    }

    @Test(
        "家事テンプレートに関する行動を、action/resultのパラメータを持つhousework_templateイベントに変換する",
        arguments: [
            (
                HouseworkTemplateAnalyticsAction.apply(isSuccess: true),
                ["action": "apply", "result": "success"]
            ),
            (
                HouseworkTemplateAnalyticsAction.apply(isSuccess: false),
                ["action": "apply", "result": "failure"]
            ),
            (
                HouseworkTemplateAnalyticsAction.create(isSuccess: true),
                ["action": "create", "result": "success"]
            ),
            (
                HouseworkTemplateAnalyticsAction.create(isSuccess: false),
                ["action": "create", "result": "failure"]
            ),
            (
                HouseworkTemplateAnalyticsAction.edit(isSuccess: true),
                ["action": "edit", "result": "success"]
            ),
            (
                HouseworkTemplateAnalyticsAction.edit(isSuccess: false),
                ["action": "edit", "result": "failure"]
            ),
            (
                HouseworkTemplateAnalyticsAction.delete(isSuccess: true),
                ["action": "delete", "result": "success"]
            ),
            (
                HouseworkTemplateAnalyticsAction.delete(isSuccess: false),
                ["action": "delete", "result": "failure"]
            ),
        ]
    )
    func houseworkTemplate(action: HouseworkTemplateAnalyticsAction, expectedParameters: [String: String]) {
        let actual = AnalyticsEvent.houseworkTemplate(action)

        #expect(actual == AnalyticsEvent(name: "housework_template", parameters: expectedParameters))
    }

    @Test(
        "同居人グループ作成フローの進捗を、method/action/resultのパラメータを持つcohabitant_registrationイベントに変換する",
        arguments: [
            (
                CohabitantRegistrationAnalyticsAction.started(method: .p2p),
                ["method": "p2p", "action": "started"]
            ),
            (
                CohabitantRegistrationAnalyticsAction.started(method: .link),
                ["method": "link", "action": "started"]
            ),
            (
                CohabitantRegistrationAnalyticsAction.peerFound,
                ["method": "p2p", "action": "peer_found"]
            ),
            (
                CohabitantRegistrationAnalyticsAction.completed(method: .p2p, isSuccess: true),
                ["method": "p2p", "action": "completed", "result": "success"]
            ),
            (
                CohabitantRegistrationAnalyticsAction.completed(method: .p2p, isSuccess: false),
                ["method": "p2p", "action": "completed", "result": "failure"]
            ),
            (
                CohabitantRegistrationAnalyticsAction.completed(method: .link, isSuccess: true),
                ["method": "link", "action": "completed", "result": "success"]
            ),
            (
                CohabitantRegistrationAnalyticsAction.completed(method: .link, isSuccess: false),
                ["method": "link", "action": "completed", "result": "failure"]
            ),
        ]
    )
    func cohabitantRegistration(
        action: CohabitantRegistrationAnalyticsAction,
        expectedParameters: [String: String]
    ) {
        let actual = AnalyticsEvent.cohabitantRegistration(action)

        #expect(actual == AnalyticsEvent(name: "cohabitant_registration", parameters: expectedParameters))
    }

    @Test(
        "プッシュ通知の権限リクエストに関する行動を、step/action/resultのパラメータを持つnotification_permissionイベントに変換する",
        arguments: [
            (
                NotificationPermissionAnalyticsAction.permissionRequested(step: .onboarding, isGranted: true),
                ["step": "onboarding", "action": "permission_requested", "result": "granted"]
            ),
            (
                NotificationPermissionAnalyticsAction.permissionRequested(step: .onboarding, isGranted: false),
                ["step": "onboarding", "action": "permission_requested", "result": "denied"]
            ),
            (
                NotificationPermissionAnalyticsAction.permissionRequested(step: .setting, isGranted: true),
                ["step": "setting", "action": "permission_requested", "result": "granted"]
            ),
            (
                NotificationPermissionAnalyticsAction.permissionRequested(step: .setting, isGranted: false),
                ["step": "setting", "action": "permission_requested", "result": "denied"]
            ),
            (
                NotificationPermissionAnalyticsAction.permissionRequested(step: .setting, isGranted: nil),
                ["step": "setting", "action": "permission_requested"]
            ),
            (
                NotificationPermissionAnalyticsAction.skipped(step: .onboarding),
                ["step": "onboarding", "action": "skipped"]
            ),
            (
                NotificationPermissionAnalyticsAction.skipped(step: .setting),
                ["step": "setting", "action": "skipped"]
            ),
        ]
    )
    func notificationPermission(
        action: NotificationPermissionAnalyticsAction,
        expectedParameters: [String: String]
    ) {
        let actual = AnalyticsEvent.notificationPermission(action)

        #expect(actual == AnalyticsEvent(name: "notification_permission", parameters: expectedParameters))
    }

}
