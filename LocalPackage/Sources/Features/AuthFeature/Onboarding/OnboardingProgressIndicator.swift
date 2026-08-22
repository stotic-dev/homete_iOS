//
//  OnboardingProgressIndicator.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// オンボーディングが全何ステップ中のどこまで進んだかを表すページドット
/// - Note: 一方向のフローで戻る導線を持たないため、ドットはタップできない表示専用のコンポーネントとする
struct OnboardingProgressIndicator: View {

    /// 実際に案内するステップの並び。スキップされるステップを含めないため、フロー側から受け取る
    let steps: [OnboardingStep]
    let currentStep: OnboardingStep

    var body: some View {
        HStack(spacing: .space8) {
            ForEach(steps, id: \.self) { step in
                Circle()
                    .fill(color(of: step))
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("全\(steps.count)ステップ中\(currentIndex + 1)ステップ目")
    }

}

// MARK: UI定義

private extension OnboardingProgressIndicator {

    var dotSize: CGFloat {
        8
    }

    /// 先頭から数えた現在地（0始まり）
    var currentIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }

    /// 到達済みのステップはアクセントカラーで塗りつぶし、未到達のステップは薄く表示する
    /// - Note: `primary3`は背景に使う淡い色で、`surface`の上ではほとんど識別できないため到達済みには使わない
    func color(of step: OnboardingStep) -> Color {
        guard let index = steps.firstIndex(of: step) else { return .clear }

        return index <= currentIndex ? .primary1 : Color.primary2.opacity(0.3)
    }

}

#Preview("OnboardingProgressIndicator", traits: .sizeThatFitsLayout) {
    VStack(spacing: .space16) {
        ForEach(OnboardingStep.allCases, id: \.self) { step in
            OnboardingProgressIndicator(steps: OnboardingStep.allCases, currentStep: step)
        }
        // 通知の権限が決定済みで、通知のステップがスキップされる場合
        OnboardingProgressIndicator(
            steps: [.registration, .premiumIntroduction],
            currentStep: .premiumIntroduction
        )
    }
    .padding(.space16)
}
