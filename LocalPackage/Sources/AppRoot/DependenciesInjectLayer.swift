//
//  DependenciesInjectLayer.swift
//

import HometeDomain
import SwiftUI

public struct DependenciesInjectLayer<Content: View>: View {

    @Environment(\.appDependencies) var appDependencies
    let content: (AppDependencies) -> Content

    public init(@ViewBuilder content: @escaping (AppDependencies) -> Content) {

        self.content = content
    }

    public var body: some View {
        content(appDependencies)
    }
}
