//
//  LoginContext.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

import SwiftUI

public struct LoginContext: Equatable {

    public let account: Account

    /// パートナー登録済みかどうか
    public var hasCohabitant: Bool { account.cohabitantId != nil }

    public init(account: Account) {
        self.account = account
    }
}

public extension EnvironmentValues {

    @Entry var loginContext = LoginContext(account: .init(id: "", userName: "", fcmToken: nil, cohabitantId: nil))
}
