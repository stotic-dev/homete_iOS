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

    /// オンボーディング中の行動
    /// - Note: 行動ごとにイベント名を増やさず、`step` / `action` / `result` パラメータで区別する。
    ///         意図は`OnboardingAnalyticsAction`を参照
    static func onboarding(_ action: OnboardingAnalyticsAction) -> Self {
        .init(
            name: "onboarding",
            parameters: action.parameters
        )
    }

}
