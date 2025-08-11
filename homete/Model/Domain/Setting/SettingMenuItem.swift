//
//  SettingMenuItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable sorted_enum_cases
enum SettingMenuItem: Equatable, CaseIterable {
    
    case taskTemplate
    case privacyPolicy
    case license
    
    var title: LocalizedStringKey {
        
        switch self {
        case .taskTemplate:
            return "家事テンプレート"
            
        case .privacyPolicy:
            return "プライバシーポリシー"
            
        case .license:
            return "ライセンス"
        }
    }
    
    var iconName: String {
        
        switch self {
        case .taskTemplate:
            return "house"
            
        case .privacyPolicy:
            return "hand.raised"
            
        case .license:
            return "cube.box"
        }
    }
}
