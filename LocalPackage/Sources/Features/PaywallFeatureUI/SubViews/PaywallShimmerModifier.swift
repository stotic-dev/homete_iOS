//
//  PaywallShimmerModifier.swift
//  LocalPackage
//

import HometeModel
import SwiftUI

/// 光の帯が左から右へ通り抜ける演出。間を空けてくり返す
///
/// 光は形に合わせて切り抜かないので、呼び出し側で`clipShape`する。
/// 帯は止まっている間は左の外に置いているので、スナップショットには写らない。視差効果を減らす設定が有効なら動かさない。
public struct PaywallShimmerModifier: ViewModifier, Sendable {

    @Environment(\.accessibilityReduceMotion) private var isReduceMotion

    public init() {}

    public func body(content: Content) -> some View {
        if isReduceMotion {
            content
        } else {
            content
                .keyframeAnimator(initialValue: ShimmerPosition.rest, repeating: true) { content, position in
                    content.overlay {
                        GeometryReader { proxy in
                            LinearGradient(
                                colors: [.white.opacity(0), .white.opacity(0.7), .white.opacity(0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: proxy.size.width * 0.4)
                            .rotationEffect(.degrees(20))
                            .offset(x: proxy.size.width * position)
                        }
                        .allowsHitTesting(false)
                    }
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(ShimmerPosition.rest, duration: 1.6)
                        CubicKeyframe(ShimmerPosition.end, duration: 0.9)
                    }
                }
        }
    }

}

/// 光の帯の位置。幅に対する割合
private enum ShimmerPosition {

    /// 止まっている位置（左の外）
    static let rest: CGFloat = -0.8
    /// 通り抜けた位置（右の外）
    static let end: CGFloat = 1.2

}

public extension View {

    /// 光の帯が通り抜ける演出を付ける
    func paywallShimmer() -> some View {
        modifier(PaywallShimmerModifier())
    }

}
