//
//  AppNavigationStackView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import SwiftUI

public struct AppNavigationStackView<Content: View>: View {
    @State private var navigationPath = AppNavigationPath(path: [])
    private let content: (_ navigationPath: AppNavigationPath) -> Content

    public init(@ViewBuilder content: @escaping (_ navigationPath: AppNavigationPath) -> Content) {
        self.content = content
    }

    public var body: some View {
        NavigationStack(path: $navigationPath.path) {
            content(navigationPath)
                .background(.surface)
                .foregroundStyle(.onSurface)
        }
        .environment(\.appNavigationPath, navigationPath)
    }
}
