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
    case setting
    case registerCohabitant
    
    @ViewBuilder
    func destination() -> some View {
        switch self {
        case .home: HomeView()
        case .setting: SettingView()
        case .registerCohabitant: RegisterCohabitantView()
        }
    }
}

extension EnvironmentValues {
    
    @Entry var rootNavigationPath = CustomNavigationPath<RootNavigationPath>(path: [])
}

extension CustomNavigationPath where Element == RootNavigationPath {
    
    func showSettingView() {
        
        path.append(.setting)
    }
    
    func showRegisterCohabitantView() {
        
        path.append(.registerCohabitant)
    }
}
