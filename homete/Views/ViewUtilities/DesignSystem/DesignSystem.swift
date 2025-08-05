//
//  DesignSystem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/05.
//

import SwiftUI

enum DesignSystem {}

// MARK: Spaceの定義

extension DesignSystem {
    
    enum Space {
                
        static let space8: CGFloat = 8
        static let space16: CGFloat = 16
        static let space24: CGFloat = 24
        static let space32: CGFloat = 32
        static let space40: CGFloat = 40
        static let space48: CGFloat = 48
        static let space56: CGFloat = 56
        static let space64: CGFloat = 64
    }
}

// MARK: Fontの定義

extension DesignSystem {
    
    enum Font {
        
        case headLineL
        case headLineM
        case headLineS
        case body
        case caption
        
        var value: SwiftUI.Font {
            
            switch self {
                
            case .headLineL: .title
            case .headLineM: .title2
            case .headLineS: .title3
            case .body: .body
            case .caption: .caption
            }
        }
    }
}

extension View {
    
    func font(_ designSystem: DesignSystem.Font) -> some View {
        
        return self.font(designSystem.value)
    }
}
