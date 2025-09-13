//
//  FloatingButtonStyle.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import SwiftUI

struct FloatingButtonStyle: ButtonStyle {
    
    let isDisable: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .padding(DesignSystem.Space.space16)
                .foregroundStyle(.commonBlack)
                .glassEffect(
                    .regular.tint(.primary1).interactive(!isDisable)
                )
                .opacity(isDisable ? 0.5 : 1)
                .disabled(isDisable)
        } else {
            configuration.label
                .padding(DesignSystem.Space.space16)
                .foregroundStyle(.commonBlack)
                .clipShape(Circle())
                .background {
                    Circle()
                        .foregroundStyle(.primary1)
                }
                .opacity(configuration.isPressed || isDisable ? 0.5 : 1)
                .disabled(isDisable)
        }
    }
}

extension View {
    
    /// 宙に浮いたようなボタンのスタイル
    /// - Parameters:
    ///   - isDisable: ボタンが無効であるかどうか
    /// - Description: iOS26ではLiquid Glassの効果があるボタンになる
    func floatingButtonStyle(isDisable: Bool = false) -> some View {
        self.buttonStyle(FloatingButtonStyle(isDisable: isDisable))
    }
}

#Preview("テキストボタン") {
    Button("Button") {}
        .floatingButtonStyle()
}

#Preview("アイコンボタン") {
    Button {} label: {
        Image(systemName: "plus")
    }
    .floatingButtonStyle()
}

#Preview("無効状態") {
    Button {} label: {
        Image(systemName: "plus")
    }
    .floatingButtonStyle(isDisable: true)
}
