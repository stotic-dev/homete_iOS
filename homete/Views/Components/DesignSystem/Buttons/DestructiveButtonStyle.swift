//
//  DestructiveButtonStyle.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import SwiftUI

struct DestructiveButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .commonStyle(.onDestructive)
            .background(.destructive)
            .cornerRadius(.radius16)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

extension View {
    
    func destructiveButtonStyle() -> some View {
        self.buttonStyle(DestructiveButtonStyle())
    }
}

#Preview("DestructiveButtonStyle_Enabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .destructiveButtonStyle()
}

#Preview("DestructiveButtonStyle_Disabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .destructiveButtonStyle()
        .disabled(true)
}
