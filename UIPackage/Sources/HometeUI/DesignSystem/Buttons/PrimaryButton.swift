//
//  PrimaryButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

/// 画面の主な操作のボタン
///
/// 下に厚みを付け、押すと厚みの分だけ沈む。
struct PrimaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled

    /// 下に付ける厚み
    private let depth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .commonStyle(.textOnAccent, dimsOnPress: false)
            .background(.fillAccent, in: Capsule())
            .offset(y: configuration.isPressed ? depth : 0)
            .background {
                // 厚みは主役の緑を暗くして表す。ライト・ダークのどちらでも面より暗く見える
                Capsule()
                    .fill(.fillAccent)
                    .overlay(Capsule().fill(.black.opacity(0.25)))
                    .offset(y: depth)
            }
            // 厚みの分も場所を取り、下の要素に重ならないようにする
            .padding(.bottom, depth)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.5)
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
}

#Preview("PrimaryButtonStyle_Disabled", traits: .sizeThatFitsLayout) {
    Button("Button") {}
        .primaryButtonStyle()
        .disabled(true)
}
