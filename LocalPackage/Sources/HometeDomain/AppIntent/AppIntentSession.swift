//
//  AppIntentSession.swift
//  LocalPackage
//

/// App Intentを実行する人と、その人が所属する同居人グループ
public struct AppIntentSession: Equatable, Sendable {

    public let account: Account
    public let cohabitantId: String

    public init(account: Account, cohabitantId: String) {
        self.account = account
        self.cohabitantId = cohabitantId
    }

}
