//
//  PaywallCrownEmblem.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// プレミアムプランの王冠の絵。王冠がゆっくり浮き沈みし、まわりの星がまたたく
///
/// 動きの始まりと終わりは止まった姿勢にそろえているので、スナップショットでは止まった姿勢で写る。
/// 視差効果を減らす設定が有効なら動かさない。
public struct PaywallCrownEmblem: View {

    @Environment(\.accessibilityReduceMotion) private var isReduceMotion

    public init() {}

    public var body: some View {
        ZStack {
            if isReduceMotion {
                halo(scale: 1)
                crown
            } else {
                animatedCrown
            }
            sparkle(size: 18, delay: 0.2)
                .offset(x: -56, y: -30)
            sparkle(size: 12, delay: 0.9)
                .offset(x: 58, y: -42)
            sparkle(size: 14, delay: 1.6)
                .offset(x: 48, y: 34)
        }
        .frame(width: 160, height: 128)
        .accessibilityHidden(true)
    }

}

// MARK: UI定義

private extension PaywallCrownEmblem {

    var crown: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.fillReward, .textReward],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    /// 王冠の後ろの光
    func halo(scale: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.fillReward.opacity(0.35), Color.fillReward.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 64
                    )
                )
                .frame(width: 128, height: 128)
                .scaleEffect(scale)
            Circle()
                .fill(.fillRewardSubtle)
                .frame(width: 88, height: 88)
        }
    }

    var animatedCrown: some View {
        ZStack {
            halo(scale: 1)
                .keyframeAnimator(initialValue: CGFloat(1), repeating: true) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(1, duration: 0.4)
                        CubicKeyframe(1.08, duration: 1.2)
                        CubicKeyframe(1, duration: 1.2)
                    }
                }
            crown
                .keyframeAnimator(initialValue: CGFloat(0), repeating: true) { content, offset in
                    content.offset(y: offset)
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(0, duration: 0.4)
                        CubicKeyframe(-6, duration: 1.2)
                        CubicKeyframe(0, duration: 1.2)
                    }
                }
        }
    }

    /// またたく星。`delay`をずらして、星ごとにまたたく時をずらす
    @ViewBuilder
    func sparkle(size: CGFloat, delay: TimeInterval) -> some View {
        let star = Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(.fillReward)
        if isReduceMotion {
            star
        } else {
            star
                .keyframeAnimator(initialValue: CGFloat(1), repeating: true) { content, scale in
                    content
                        .scaleEffect(scale)
                        .opacity(scale)
                } keyframes: { _ in
                    // 1周の長さを王冠とそろえ、星どうしのずれが保たれるようにする
                    KeyframeTrack {
                        LinearKeyframe(1, duration: delay)
                        CubicKeyframe(0.3, duration: 0.4)
                        CubicKeyframe(1, duration: 0.4)
                        LinearKeyframe(1, duration: 2.8 - delay - 0.8)
                    }
                }
        }
    }

}

#Preview("PaywallCrownEmblem", traits: .sizeThatFitsLayout) {
    PaywallCrownEmblem()
        .padding()
}
