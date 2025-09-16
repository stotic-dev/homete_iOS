//
//  HomeNavigationPath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/13.
//

import SwiftUI

enum HomeNavigationPathElement {
    
    case settings
    
    @ViewBuilder
    func destination() -> some View {
        switch self {
        case .settings: SettingView()
        }
    }
}

extension EnvironmentValues {
    
    @Entry var homeNavigationPath = CustomNavigationPath<HomeNavigationPathElement>(path: [])
}
