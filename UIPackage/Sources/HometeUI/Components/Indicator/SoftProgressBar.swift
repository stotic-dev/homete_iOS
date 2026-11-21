//
//  SoftProgressBar.swift
//  LocalPackage
//

import HometeResources
import SwiftUI

/// 進み具合を、角の丸い太めのバーで見せる
///
/// 読み上げる内容は置く場所によって変わるため、呼び出し側で数や文言と合わせて読み上げる。
public struct SoftProgressBar: View {

    /// 0.0〜1.0。範囲の外は丸める
    let value: Double

    public init(value: Double) {
        self.value = value
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.fillAccentSubtle)
                if clampedValue > 0 {
                    Capsule()
                        .fill(.fillAccent)
                        // 少しだけ進んだときも、丸い端が潰れないよう高さぶんの幅は残す
                        .frame(width: max(geometry.size.width * clampedValue, geometry.size.height))
                }
            }
        }
        .frame(height: 10)
        .animation(.spring(duration: 0.5), value: clampedValue)
    }

}

private extension SoftProgressBar {

    var clampedValue: Double {
        min(max(value, 0), 1)
    }

}

#Preview("SoftProgressBar", traits: .sizeThatFitsLayout) {
    VStack(spacing: .space16) {
        SoftProgressBar(value: 0)
        SoftProgressBar(value: 0.02)
        SoftProgressBar(value: 0.6)
        SoftProgressBar(value: 1)
    }
    .padding(.space16)
}
