//
//  LoginContext.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

public struct LoginContext: Equatable {

    public let account: Account

    /// パートナー登録済みかどうか
    public var hasCohabitant: Bool { account.cohabitantId != nil }
    /// 家族ID
    public var cohabitantId: String? { account.cohabitantId }

    public init(account: Account) {
        self.account = account
    }
}
