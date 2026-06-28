//
//  PrimaryButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .commonStyle()
            .background {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: proxy.size.height / 2)
                        .fill(.primary3)
                }
            }
            .opacity(isEnabled ? 1 : 0.5)
            .disabled(!isEnabled)
    }

}

public extension View {

    func primaryButtonStyle() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }

}

#Preview("PrimaryButtonStyle_Enabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .primaryButtonStyle()
        .snapshotForPreview(precision: 0.85, perceptualPrecision: 0.85)
}

#Preview("PrimaryButtonStyle_Disabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .primaryButtonStyle()
        .disabled(true)
}
