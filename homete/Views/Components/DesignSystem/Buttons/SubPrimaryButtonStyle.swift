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

#Preview("Enabled") {
    Button("Button") {}
        .subPrimaryButtonStyle()
}

#Preview("Disabled") {
    Button("Button") {}
        .subPrimaryButtonStyle(isDisabled: true)
}
