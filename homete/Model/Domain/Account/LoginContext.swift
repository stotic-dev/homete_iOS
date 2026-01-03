//
//  LoginContext.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

import SwiftUI

struct LoginContext: Equatable {
    
    let account: Account
    
    /// パートナー登録済みかどうか
    var hasCohabitant: Bool { account.cohabitantId != nil }
}

extension EnvironmentValues {
    
    @Entry var loginContext = LoginContext(account: .init(id: "", userName: "", fcmToken: nil, cohabitantId: nil))
}
