//
//  Account.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

// TODO: ダミー
public struct Account: Equatable, Codable, Sendable {

    public let id: String
    public let userName: String
    public let fcmToken: String?
    public let cohabitantId: String?

    public init(id: String, userName: String, fcmToken: String?, cohabitantId: String?) {
        self.id = id
        self.userName = userName
        self.fcmToken = fcmToken
        self.cohabitantId = cohabitantId
    }
}

public extension Account {

    static func initial(auth: AccountAuthResult, userName: UserName, fcmToken: String?) -> Self {

        return .init(id: auth.id, userName: userName.value, fcmToken: fcmToken, cohabitantId: nil)
    }
}
