//
//  AppNavigationPath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

@Observable
public final class AppNavigationPath<Route: Hashable> {

    public var path: [Route]

    public init(path: [Route] = []) {
        self.path = path
    }

    public func popToRoot() {

        path.removeAll()
    }

    public func pop() {

        _ = path.popLast()
    }

    public func push(_ route: Route) {

        path.append(route)
    }
}
