//
//  LoginContext.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

import SwiftUI

struct LoginContext: Equatable {
    
    let account: Account
}

extension EnvironmentValues {
    
    @Entry var loginContext = LoginContext(account: .init(id: "", userName: "", fcmToken: nil))
}
