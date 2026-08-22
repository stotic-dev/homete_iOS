//
//  OnboardingProgressIndicator.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// オンボーディングが全何ステップ中のどこまで進んだかを表すページドット
/// - Note: 一方向のフローで戻る導線を持たないため、ドットはタップできない表示専用のコンポーネントとする
struct OnboardingProgressIndicator: View {

    let currentStep: OnboardingStep

    var body: some View {
        HStack(spacing: .space8) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Circle()
                    .fill(color(of: step))
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("全\(OnboardingStep.allCases.count)ステップ中\(currentStep.order)ステップ目")
    }

}

// MARK: UI定義

private extension OnboardingProgressIndicator {

    var dotSize: CGFloat {
        8
    }

    /// 到達済みのステップは塗りつぶし、未到達のステップは薄く表示する
    func color(of step: OnboardingStep) -> Color {
        step.order <= currentStep.order ? .primary3 : Color.primary2.opacity(0.3)
    }

}

#Preview("OnboardingProgressIndicator", traits: .sizeThatFitsLayout) {
    VStack(spacing: .space16) {
        ForEach(OnboardingStep.allCases, id: \.self) { step in
            OnboardingProgressIndicator(currentStep: step)
        }
    }
    .padding(.space16)
}
