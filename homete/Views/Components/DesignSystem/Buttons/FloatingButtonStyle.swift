//
//  FloatingButtonStyle.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import SwiftUI

struct FloatingButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.space16)
            .foregroundStyle(.onSurface)
            .background {
                GeometryReader {
                    RoundedRectangle(cornerRadius: $0.size.height / 2)
                        .fill(.primary1)
                }
            }
            .opacity(configuration.isPressed || !isEnabled ? 0.5 : 1)
            .addGlassEffect(!isEnabled)
    }
}

private extension View {
    
    func addGlassEffect(_ isDisable: Bool) -> some View {
        if #available(iOS 26.0, *) {
            return self.glassEffect(.regular.interactive(!isDisable))
        } else {
            return self
        }
    }
}

extension View {
    
    /// 宙に浮いたようなボタンのスタイル
    /// - Description: iOS26ではLiquid Glassの効果があるボタンになる
    func floatingButtonStyle() -> some View {
        self.buttonStyle(FloatingButtonStyle())
    }
}

#Preview("FloatingButtonStyle_テキストボタン", traits: .sizeThatFitsLayout) {
    Button("Button") {
        print("tapped")
    }
    .floatingButtonStyle()
}

#Preview("FloatingButtonStyle_アイコンボタン", traits: .sizeThatFitsLayout) {
    Button {
        print("tapped")
    } label: {
        Image(systemName: "plus")
    }
    .floatingButtonStyle()
}

#Preview("FloatingButtonStyle_無効状態", traits: .sizeThatFitsLayout) {
    Button {} label: {
        Image(systemName: "plus")
    }
    .floatingButtonStyle()
    .disabled(true)
}
