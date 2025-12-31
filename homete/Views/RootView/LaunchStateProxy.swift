//
//  LaunchStateProxy.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

import SwiftUI

struct LaunchStateProxy {
    @Binding private var launchState: LaunchState
    
    init(launchState: Binding<LaunchState>) {
        _launchState = launchState
    }
    
    func callAsFunction(_ next: LaunchState) {
        launchState = next
    }
}

extension EnvironmentValues {
    @Entry var launchStateProxy = LaunchStateProxy(launchState: .constant(.notLoggedIn))
}
