//
//  SettingMenuItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

enum SettingMenuItem: Equatable, CaseIterable {
    
    case privacyPolicy
    case license
    case taskTemplate
    
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
