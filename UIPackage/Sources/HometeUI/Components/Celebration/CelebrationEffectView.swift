//
//  CelebrationEffectView.swift
//  LocalPackage
//

import SwiftUI

/// クラッカーが弾けたあと、花吹雪が降り続ける祝いの演出
///
/// 画面の上に重ねて使う。紙片のレイヤーは下のボタンのタップを奪わない。
public struct CelebrationEffectView: View {

    /// クラッカーが弾け終わったかどうか
    @State private var isCracked = false

    public init() {}

    public var body: some View {
        celebration()
            .ignoresSafeArea()
            // 紙片のレイヤーが下のボタンのタップを奪わないようにする
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

}

private extension CelebrationEffectView {

    @ViewBuilder
    func celebration() -> some View {
        if isCracked {
            ConfettiRainView()
        } else {
            CrackerView {
                withAnimation {
                    isCracked = true
                }
            }
            .transition(.opacity)
        }
    }

}
