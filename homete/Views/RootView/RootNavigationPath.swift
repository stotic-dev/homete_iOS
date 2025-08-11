//
//  RootNavigationPath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

@MainActor
enum RootNavigationPath: Hashable {
    
    case home
    
    @ViewBuilder
    func destination() -> some View {
        switch self {
        case .home: HomeView()
        }
    }
}

extension EnvironmentValues {
    
    @Entry var rootNavigationPath = CustomNavigationPath<RootNavigationPath>(path: [])
}
