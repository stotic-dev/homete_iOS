//
//  RouteResolver.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

public struct RouteResolver: Sendable {

    public var resolve: @MainActor @Sendable (AppRoute) -> AnyView

    public init(resolve: @escaping @MainActor @Sendable (AppRoute) -> AnyView) {
        self.resolve = resolve
    }
}

public extension EnvironmentValues {
    @Entry var routeResolver: RouteResolver = .preview
}

public extension RouteResolver {
    static let preview = RouteResolver { route in
        AnyView(Text("Preview: \(String(describing: route))"))
    }
}
