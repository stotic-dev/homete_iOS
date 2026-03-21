//
//  RouteResolver.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

public struct RouteResolver<V: View>: Sendable {

    @ViewBuilder
    public var resolve: @MainActor (AppRoute) -> V

    public init(
        @ViewBuilder resolve: @escaping @MainActor (AppRoute) -> V
    ) {
        self.resolve = resolve
    }
}
