//
//  RouteResolver.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

public struct RouteResolver: Sendable {

    private var _resolve: @MainActor @Sendable (AppRoute) -> AnyView

    public init<V: View>(
        @ViewBuilder resolve: @escaping @MainActor @Sendable (AppRoute) -> V
    ) {
        _resolve = { AnyView(resolve($0)) }
    }

    @MainActor
    public func resolve(_ route: AppRoute) -> some View {
        _resolve(route)
    }
}

public extension EnvironmentValues {
    @Entry var routeResolver: RouteResolver = .preview
}

public extension RouteResolver {
    static let preview = RouteResolver { route in
        Text("Preview: \(String(describing: route))")
    }
}
