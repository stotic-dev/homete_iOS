//
//  ThanksButtonStyle.swift
//  LocalPackage
//

import SwiftUI

/// ありがとうを伝えるボタン
///
/// 主役の緑と見分けられるよう、ありがとう専用の色にする。
struct ThanksButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .commonStyle(.textThanks)
            .background(.fillThanksSubtle, in: Capsule())
            .opacity(isEnabled ? 1 : 0.5)
    }

}

public extension View {

    func thanksButtonStyle() -> some View {
        buttonStyle(ThanksButtonStyle())
    }

}

#Preview("ThanksButtonStyle_Enabled", traits: .sizeThatFitsLayout) {
    Button("ありがとう", systemImage: "heart.fill") {}
        .thanksButtonStyle()
}

#Preview("ThanksButtonStyle_Disabled", traits: .sizeThatFitsLayout) {
    Button("ありがとう", systemImage: "heart.fill") {}
        .thanksButtonStyle()
        .disabled(true)
}
