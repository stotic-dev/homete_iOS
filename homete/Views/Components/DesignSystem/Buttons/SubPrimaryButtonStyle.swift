//
//  SubPrimaryButtonStyle.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/20.
//

import SwiftUI

struct SubPrimaryButtonStyle: ButtonStyle {
    
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .commonStyle()
            .background(.primary1)
            .cornerRadius(.radius16)
            .opacity(isDisabled ? 0.5 : 1)
            .disabled(isDisabled)
    }
}
extension View {
    
    func subPrimaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(SubPrimaryButtonStyle(isDisabled: isDisabled))
    }
}

#Preview("SubPrimaryButtonStyle_Enabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .subPrimaryButtonStyle()
}

#Preview("SubPrimaryButtonStyle_Disabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .subPrimaryButtonStyle(isDisabled: true)
}
