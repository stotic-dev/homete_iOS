//
//  RootNavigationPath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

@MainActor
enum RootNavigationPath: Hashable {
    case content
    
    @ViewBuilder
    func Destination() -> some View {
        switch self {
        case .content: ContentView()
        }
    }
}

extension EnvironmentValues {
    @Entry var rootNavigationPath = CustomNavigationPath<RootNavigationPath>(path: [])
}

extension CustomNavigationPath where Element == RootNavigationPath {
    func showContent() {
        path.append(.content)
    }
}
