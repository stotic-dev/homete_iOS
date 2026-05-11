//
//  LaunchStateProxy.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

import SwiftUI

public struct LaunchStateProxy {

    @Binding private var launchState: LaunchState

    public init(launchState: Binding<LaunchState>) {
        _launchState = launchState
    }

    public func callAsFunction(_ next: LaunchState) {
        launchState = next
    }

}

public extension EnvironmentValues {

    @Entry var launchStateProxy = LaunchStateProxy(launchState: .constant(.notLoggedIn))

}
