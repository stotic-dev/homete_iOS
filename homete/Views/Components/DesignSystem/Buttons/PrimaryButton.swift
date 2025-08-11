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
        configuration.label
            .font(with: .headLineS)
            .padding(.horizontal, DesignSystem.Space.space16)
            .padding(.vertical, DesignSystem.Space.space8)
            .foregroundStyle(
                Color(isDisabled ? .commonWhite :  .commonBlack).opacity(configuration.isPressed ? 0.3 : 1)
            )
            .background {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: proxy.size.height / 2)
                        .fill(isDisabled ? .gray : Color(.primary3))
                }
            }
            .disabled(isDisabled)
    }
}

extension View {
    
    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isDisabled: isDisabled))
    }
}

#Preview("Enabled") {
    Button("Button") {}
        .primaryButtonStyle()
}

#Preview("Disabled") {
    Button("Button") {}
        .primaryButtonStyle(isDisabled: true)
}
