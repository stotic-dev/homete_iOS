//
//  AppNavigationStackView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import SwiftUI

public struct AppNavigationStackView<Route: Hashable, Content: View>: View {
    private let path: Binding<[Route]>?
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) where Route == Never {
        self.path = nil
        self.content = content
    }

    public init(path: Binding<[Route]>, @ViewBuilder content: @escaping () -> Content) {
        self.path = path
        self.content = content
    }

    public var body: some View {
        if let path {
            NavigationStack(path: path) {
                content()
                    .background(.surface)
                    .foregroundStyle(.onSurface)
            }
        } else {
            NavigationStack {
                content()
                    .background(.surface)
                    .foregroundStyle(.onSurface)
            }
        }
    }
}
