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
        configuration.label
            .padding(DesignSystem.Space.space16)
            .foregroundStyle(.commonBlack)
            .background {
                GeometryReader {
                    RoundedRectangle(cornerRadius: $0.size.height / 2)
                        .fill(.primary1)
                }
            }
            .opacity(configuration.isPressed || isDisable ? 0.5 : 1)
            .disabled(isDisable)
    }
}

extension View {
    
    /// 宙に浮いたようなボタンのスタイル
    /// - Parameters:
    ///   - isDisable: ボタンが無効であるかどうか
    /// - Description: iOS26ではLiquid Glassの効果があるボタンになる
    func floatingButtonStyle(isDisable: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            return self.buttonStyle(FloatingButtonStyle(isDisable: isDisable))
                .glassEffect(.regular.interactive(!isDisable))
        } else {
            return self.buttonStyle(FloatingButtonStyle(isDisable: isDisable))
        }
    }
}

#Preview("テキストボタン") {
    Button("Button") {
        print("tapped")
    }
    .floatingButtonStyle()
}

#Preview("アイコンボタン") {
    Button {
        print("tapped")
    } label: {
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
