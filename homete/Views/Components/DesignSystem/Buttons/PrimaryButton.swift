//
//  PrimaryButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .commonStyle()
            .background {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: proxy.size.height / 2)
                        .fill(.primary3)
                }
            }
            .opacity(isDisabled ? 0.5 : 1)
            .disabled(isDisabled)
    }
}

extension View {
    
    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isDisabled: isDisabled))
    }
}

#Preview("PrimaryButtonStyle_Enabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .primaryButtonStyle()
}

#Preview("PrimaryButtonStyle_Disabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .primaryButtonStyle(isDisabled: true)
}
