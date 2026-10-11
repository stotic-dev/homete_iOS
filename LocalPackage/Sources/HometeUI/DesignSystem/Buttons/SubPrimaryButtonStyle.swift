//
//  SubPrimaryButtonStyle.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/20.
//

import SwiftUI

/// 主な操作に並ぶ副の操作や、「もっと見る」のような補助の操作のボタン
struct SubPrimaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .commonStyle(.textAccent)
            .background(.fillAccentSubtle, in: Capsule())
            .opacity(isEnabled ? 1 : 0.5)
    }

}

public extension View {

    func subPrimaryButtonStyle() -> some View {
        buttonStyle(SubPrimaryButtonStyle())
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
