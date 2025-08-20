//
//  ButtonStyleUtil.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/20.
//

import SwiftUI

@MainActor
extension ButtonStyleConfiguration {
    
    func commonStyle() -> some View {
        self.label
            .font(with: .headLineS)
            .padding(.horizontal, DesignSystem.Space.space16)
            .padding(.vertical, DesignSystem.Space.space8)
            .foregroundStyle(
                Color(.commonBlack).opacity(isPressed ? 0.3 : 1)
            )
    }
}
