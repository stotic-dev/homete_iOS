//
//  AnalyticsEvent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public struct AnalyticsEvent: Equatable {

    public let name: String
    public let parameters: [String: String]

    public init(name: String, parameters: [String: String]) {
        self.name = name
        self.parameters = parameters
    }

}

public extension AnalyticsEvent {

    static func login(isSuccess: Bool) -> Self {
        .init(
            name: "login",
            parameters: ["isSuccess": "\(isSuccess)"]
        )
    }

    static func logout() -> Self {
        .init(
            name: "logout",
            parameters: [:]
        )
    }

    static func deleteAccount() -> Self {
        .init(
            name: "delete_account",
            parameters: [:]
        )
    }

    /// オンボーディングでプレミアムプランの特典説明画面を表示した
    static func onboardingPremiumIntroductionShown() -> Self {
        .init(
            name: "onboarding_premium_introduction_shown",
            parameters: [:]
        )
    }

    /// オンボーディングでプレミアムプランの特典説明画面からPaywallを開かずに次へ進んだ
    static func onboardingPremiumIntroductionSkipped() -> Self {
        .init(
            name: "onboarding_premium_introduction_skipped",
            parameters: [:]
        )
    }

    /// アカウント登録直後のオンボーディングでPaywallを表示した
    static func onboardingPaywallShown() -> Self {
        .init(
            name: "onboarding_paywall_shown",
            parameters: [:]
        )
    }

    /// アカウント登録直後のオンボーディングで表示したPaywallを閉じた
    /// - Parameter isPremium: 閉じた時点でプレミアムプランが有効かどうか（購入せずスキップした場合はfalse）
    static func onboardingPaywallClosed(isPremium: Bool) -> Self {
        .init(
            name: "onboarding_paywall_closed",
            parameters: ["isPremium": "\(isPremium)"]
        )
    }

    /// オンボーディングでプッシュ通知の権限をリクエストした
    /// - Parameter isGranted: 権限が許可されたかどうか
    static func onboardingNotificationPermissionRequested(isGranted: Bool) -> Self {
        .init(
            name: "onboarding_notification_permission_requested",
            parameters: ["isGranted": "\(isGranted)"]
        )
    }

    /// オンボーディングでプッシュ通知の権限をリクエストせずにスキップした
    static func onboardingNotificationPermissionSkipped() -> Self {
        .init(
            name: "onboarding_notification_permission_skipped",
            parameters: [:]
        )
    }

}
