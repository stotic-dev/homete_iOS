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
            parameters: ["result": isSuccess ? "success" : "failure"]
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

    /// オンボーディング中の行動
    /// - Note: 行動ごとにイベント名を増やさず、`step` / `action` / `result` パラメータで区別する。
    ///         意図は`OnboardingAnalyticsAction`を参照
    static func onboarding(_ action: OnboardingAnalyticsAction) -> Self {
        .init(
            name: "onboarding",
            parameters: action.parameters
        )
    }

    /// 画面の表示
    /// - Note: GA4の予約イベント名`screen_view`と予約パラメータ`screen_name`を使う。
    ///         SwiftUIのみで構成しているため自動収集の`screen_view`は機能せず、全画面から手動で送信する
    static func screenView(_ screen: AppScreen) -> Self {
        .init(
            name: "screen_view",
            parameters: ["screen_name": screen.screenName]
        )
    }

    /// 招待リンクに関する行動
    /// - Note: 行動ごとにイベント名を増やさず、`action` / `result` パラメータで区別する。
    ///         意図は`CohabitantInvitationAnalyticsAction`を参照
    static func cohabitantInvitation(_ action: CohabitantInvitationAnalyticsAction) -> Self {
        .init(
            name: "cohabitant_invitation",
            parameters: action.parameters
        )
    }

    /// 家事に関する行動
    /// - Note: 行動ごとにイベント名を増やさず、`action` / `step` / `result` パラメータで区別する。
    ///         意図は`HouseworkAnalyticsAction`を参照
    static func housework(_ action: HouseworkAnalyticsAction) -> Self {
        .init(
            name: "housework",
            parameters: action.parameters
        )
    }

    /// 家事テンプレートに関する行動
    /// - Note: 行動ごとにイベント名を増やさず、`action` / `result` パラメータで区別する。
    ///         意図は`HouseworkTemplateAnalyticsAction`を参照
    static func houseworkTemplate(_ action: HouseworkTemplateAnalyticsAction) -> Self {
        .init(
            name: "housework_template",
            parameters: action.parameters
        )
    }

    /// 同居人グループ作成フローの進捗に関する行動
    /// - Note: 行動ごとにイベント名を増やさず、`method` / `action` / `result` パラメータで区別する。
    ///         意図は`CohabitantRegistrationAnalyticsAction`を参照
    static func cohabitantRegistration(_ action: CohabitantRegistrationAnalyticsAction) -> Self {
        .init(
            name: "cohabitant_registration",
            parameters: action.parameters
        )
    }

    /// プッシュ通知の権限リクエストに関する行動
    /// - Note: 行動ごとにイベント名を増やさず、`step` / `action` / `result` パラメータで区別する。
    ///         意図は`NotificationPermissionAnalyticsAction`を参照
    static func notificationPermission(_ action: NotificationPermissionAnalyticsAction) -> Self {
        .init(
            name: "notification_permission",
            parameters: action.parameters
        )
    }

    /// 広告に関する行動
    /// - Note: 現状「広告を非表示にする」リンクのタップのみのため、行動ごとのenumは持たず`step`だけで区別する
    static func advertisement(step: AdvertisementAnalyticsStep) -> Self {
        .init(
            name: "advertisement",
            parameters: ["action": "remove_ads_link_tapped", "step": step.rawValue]
        )
    }

    /// 契約中プランの管理に関する行動
    /// - Note: 行動ごとにイベント名を増やさず、`action` / `result` パラメータで区別する。
    ///         意図は`SubscriptionAnalyticsAction`を参照
    static func subscription(_ action: SubscriptionAnalyticsAction) -> Self {
        .init(
            name: "subscription",
            parameters: action.parameters
        )
    }

}
