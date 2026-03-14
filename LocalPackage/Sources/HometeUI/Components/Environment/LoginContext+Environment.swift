//
//  LoginContext+Environment.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

import HometeDomain
import SwiftUI

public extension EnvironmentValues {

    @Entry var loginContext = LoginContext(account: .init(id: "", userName: "", fcmToken: nil, cohabitantId: nil))
}
