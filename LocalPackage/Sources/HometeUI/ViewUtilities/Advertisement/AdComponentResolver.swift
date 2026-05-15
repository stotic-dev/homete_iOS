//
//  AdComponentResolver.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import Foundation
import HometeDomain
import SwiftUI

public struct AdComponentResolver: Sendable {
    private var _resolve: @MainActor @Sendable (AdType) -> AnyView

    public init<V: View>(
        @ViewBuilder resolve: @escaping @MainActor @Sendable (AdType) -> V
    ) {
        _resolve = { AnyView(resolve($0)) }
    }

    @MainActor
    public func resolve(_ type: AdType) -> some View {
        _resolve(type)
    }
}

public extension EnvironmentValues {
    @Entry var adComponentResolver: AdComponentResolver = .preview
}

public extension AdComponentResolver {
    static let preview = AdComponentResolver { type in
        Text("Preview: \(String(describing: type))")
    }
}
