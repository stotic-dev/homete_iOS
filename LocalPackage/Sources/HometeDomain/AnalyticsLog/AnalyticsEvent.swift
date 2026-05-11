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

}
