//
//  WelcomeGreeting.swift
//  LocalPackage
//

import HometeResources
import HometeUI
import SwiftUI

/// 説明画面の1枚目で、ほめっとが跳ねて手をふり、アプリへ迎え入れる絵
///
/// 跳ねてから手をふる動きを、間を空けてくり返す。動きの始まりと終わりは止まった姿勢にそろえているので、
/// スナップショットでは止まった姿勢で写る。視差効果を減らす設定が有効なら動かさない。
struct WelcomeGreeting: View {

    @Environment(\.accessibilityReduceMotion) private var isReduceMotion

    var body: some View {
        VStack(spacing: .space8) {
            speechBubble
            if isReduceMotion {
                HometteView(.wave, size: .large)
            } else {
                animatedHomette
            }
        }
        .padding(.top, .space32)
    }

}

// MARK: UI定義

private extension WelcomeGreeting {

    /// ほめっとのセリフ。ほめっとの言葉なので、くだけた口調にする
    var speechBubble: some View {
        Text("はじめまして、ほめっとだよ！", bundle: #bundle)
            .font(with: .body)
            .foregroundStyle(.textPrimary)
            .padding(.horizontal, .space16)
            .padding(.vertical, .space8)
            .background {
                RoundedRectangle(radius: .radius20)
                    .fill(.backgroundCard)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            }
    }

    var animatedHomette: some View {
        HometteView(.wave, size: .large)
            .keyframeAnimator(initialValue: GreetingMotion(), repeating: true) { content, motion in
                content
                    .rotationEffect(motion.angle, anchor: .bottom)
                    .scaleEffect(x: motion.horizontalScale, y: motion.verticalScale, anchor: .bottom)
                    .offset(y: motion.verticalOffset)
            } keyframes: { _ in
                // 跳ねる（0〜0.7秒）
                KeyframeTrack(\.verticalOffset) {
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(-28, duration: 0.25)
                    SpringKeyframe(0, duration: 0.35, spring: .bouncy)
                    LinearKeyframe(0, duration: 2.8)
                }
                // 踏み切りと着地で少しつぶれる
                KeyframeTrack(\.verticalScale) {
                    CubicKeyframe(0.92, duration: 0.1)
                    CubicKeyframe(1.04, duration: 0.25)
                    CubicKeyframe(0.95, duration: 0.15)
                    SpringKeyframe(1, duration: 0.2)
                    LinearKeyframe(1, duration: 2.8)
                }
                KeyframeTrack(\.horizontalScale) {
                    CubicKeyframe(1.06, duration: 0.1)
                    CubicKeyframe(0.97, duration: 0.25)
                    CubicKeyframe(1.04, duration: 0.15)
                    SpringKeyframe(1, duration: 0.2)
                    LinearKeyframe(1, duration: 2.8)
                }
                // 着地してから、体をゆらして手をふる（0.7〜1.9秒）
                KeyframeTrack(\.angle) {
                    LinearKeyframe(.zero, duration: 0.7)
                    CubicKeyframe(.degrees(-8), duration: 0.2)
                    CubicKeyframe(.degrees(8), duration: 0.25)
                    CubicKeyframe(.degrees(-8), duration: 0.25)
                    CubicKeyframe(.degrees(6), duration: 0.25)
                    SpringKeyframe(.zero, duration: 0.25)
                    LinearKeyframe(.zero, duration: 1.6)
                }
            }
    }

}

/// ほめっとの姿勢。初期値は止まった姿勢
private struct GreetingMotion {

    var verticalOffset: CGFloat = 0
    var verticalScale: CGFloat = 1
    var horizontalScale: CGFloat = 1
    var angle: Angle = .zero

}

#Preview("WelcomeGreeting", traits: .sizeThatFitsLayout) {
    WelcomeGreeting()
        .padding(.space16)
        .background(.backgroundScreen)
}
