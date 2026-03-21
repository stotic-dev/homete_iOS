//
//  AppNavigationStackView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import SwiftUI

public struct AppNavigationStackView<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        NavigationStack {
            content()
                .background(.surface)
                .foregroundStyle(.onSurface)
        }
    }
}
