//
//  SubPrimaryButtonStyle.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/20.
//

import SwiftUI

struct SubPrimaryButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .commonStyle()
            .background(.primary1)
            .cornerRadius(.radius16)
            .opacity(isEnabled ? 1 : 0.5)
    }
}
extension View {
    
    func subPrimaryButtonStyle() -> some View {
        self.buttonStyle(SubPrimaryButtonStyle())
    }
}

#Preview("SubPrimaryButtonStyle_Enabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .subPrimaryButtonStyle()
}

#Preview("SubPrimaryButtonStyle_Disabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .subPrimaryButtonStyle()
        .disabled(true)
}
