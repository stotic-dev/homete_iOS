//
//  AppNavigationPath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import HometeDomain
import SwiftUI

@Observable
public final class AppNavigationPath {

    public var path: [AppRoute]

    public init(path: [AppRoute]) {
        self.path = path
    }

    public func popToRoot() {

        path.removeAll()
    }

    public func pop() {

        _ = path.popLast()
    }

    public func push(_ route: AppRoute) {

        path.append(route)
    }
}

public extension EnvironmentValues {
    @Entry var appNavigationPath = AppNavigationPath(path: [])
}
