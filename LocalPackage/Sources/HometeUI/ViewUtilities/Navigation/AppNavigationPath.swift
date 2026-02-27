//
//  AppNavigationPath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

@Observable
public final class AppNavigationPath {

    public var path: [AppNavigationElement]

    public init(path: [AppNavigationElement]) {
        self.path = path
    }

    public func popToRoot() {

        path.removeAll()
    }

    public func pop() {

        _ = path.popLast()
    }

    public func push(_ element: AppNavigationElement) {

        path.append(element)
    }
}

public extension EnvironmentValues {
    @Entry var appNavigationPath = AppNavigationPath(path: [])
}
