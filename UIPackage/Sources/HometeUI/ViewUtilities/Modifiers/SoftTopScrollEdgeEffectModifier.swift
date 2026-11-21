//
//  SoftTopScrollEdgeEffectModifier.swift
//  homete
//

import SwiftUI

public extension View {

    /// iOS 27以降は`.automatic`のスクロールエッジエフェクトがナビゲーションバー直下で`.hard`寄りの見た目になり、
    /// iOS 26までの`.soft`（ぼかしで自然に馴染ませる）表示と挙動が変わってしまうため明示的に固定する
    @ViewBuilder
    func softTopScrollEdgeEffect() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
        #else
        self
        #endif
    }

}
