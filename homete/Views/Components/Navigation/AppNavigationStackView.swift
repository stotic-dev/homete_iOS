//
//  AppNavigationStackView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import SwiftUI

struct AppNavigationStackView<Content: View>: View {
    @State var navigationPath = AppNavigationPath(path: [])
    
    @ViewBuilder var content: (_ navigationPath: AppNavigationPath) -> Content
    
    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            content(navigationPath)
                .background(.primaryBg)
                .foregroundStyle(.primaryFg)
        }
        .environment(\.appNavigationPath, navigationPath)
    }
}
