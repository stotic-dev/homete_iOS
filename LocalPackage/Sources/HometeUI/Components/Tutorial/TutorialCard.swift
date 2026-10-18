//
//  TutorialCard.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// チュートリアルで、ステップごとに「どこで何ができるか」を説明するカード
///
/// 説明の対象のUIは`tutorialSpotlight`で切り抜いて見せ、このカードはその上に重ねる。
/// 操作はさせず、説明だけにとどめる。ステップごとの文言とアイコンは呼び出し側で決める。
public struct TutorialCard<Step: TutorialStep>: View {

    let step: Step
    let steps: [Step]
    let systemImage: String
    let iconForegroundStyle: Color
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let location: LocalizedStringResource?
    let onTapNext: () -> Void
    let onTapBack: () -> Void
    let onTapClose: () -> Void

    /// - Parameters:
    ///   - step: 表示するステップ。何ステップ目か・最初か最後かをここから決める
    ///   - steps: 今回出すステップ。画面の状態によって一部のステップを除くときに渡す
    ///   - systemImage: タイトルの横に出すアイコン
    ///   - iconForegroundStyle: アイコンの色
    ///   - title: 何の説明か
    ///   - message: 何ができるか
    ///   - location: どこから使えるか。説明している画面の中にあるUIなら不要
    public init(
        step: Step,
        steps: [Step] = Step.allCases,
        systemImage: String,
        iconForegroundStyle: Color,
        title: LocalizedStringResource,
        message: LocalizedStringResource,
        location: LocalizedStringResource? = nil,
        onTapNext: @escaping () -> Void,
        onTapBack: @escaping () -> Void,
        onTapClose: @escaping () -> Void
    ) {
        self.step = step
        self.steps = steps
        self.systemImage = systemImage
        self.iconForegroundStyle = iconForegroundStyle
        self.title = title
        self.message = message
        self.location = location
        self.onTapNext = onTapNext
        self.onTapBack = onTapBack
        self.onTapClose = onTapClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            header
            HStack(alignment: .top, spacing: .space16) {
                icon
                VStack(alignment: .leading, spacing: .space8) {
                    Text(title)
                        .font(with: .headLineS)
                        .foregroundStyle(.textPrimary)
                    Text(message)
                        .font(with: .body)
                        .foregroundStyle(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let location {
                        Label {
                            Text(location)
                        } icon: {
                            Image(systemName: "hand.point.up.left")
                        }
                        .font(with: .caption)
                        .foregroundStyle(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            footer
        }
        .sectionCardStyle()
        .id(stepIndex)
        .transition(.opacity)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

}

// MARK: UI定義

private extension TutorialCard {

    var header: some View {
        HStack {
            Text(verbatim: "\(stepIndex + 1) / \(stepCount)")
                .font(with: .boldCaption)
                .foregroundStyle(.textSecondary)
                .accessibilityLabel(
                    .localized(
                        "全\(stepCount)ステップ中\(stepIndex + 1)ステップ目",
                        comment: "チュートリアルの何ステップ目か。1つめは全体のステップ数、2つめは今のステップ"
                    )
                )
            Spacer()
            Button(.localized("閉じる"), action: onTapClose)
                .font(with: .caption)
                .foregroundStyle(.textSecondary)
        }
    }

    /// 「次へ」はステップによらず同じ位置に置き、続けて押せるようにする
    var footer: some View {
        HStack(spacing: .space8) {
            if !isFirstStep {
                Button(.localized("前へ"), action: onTapBack)
                    .subPrimaryButtonStyle()
            }
            Spacer()
            Button(isLastStep ? .localized("はじめる") : .localized("次へ"), action: onTapNext)
                .primaryButtonStyle()
        }
    }

    var icon: some View {
        Image(systemName: systemImage)
            .font(.title2)
            .foregroundStyle(iconForegroundStyle)
            .frame(width: .space48, height: .space48)
            .background {
                Circle()
                    .fill(.backgroundScreen)
            }
            .accessibilityHidden(true)
    }

}

// MARK: 表示の属性

private extension TutorialCard {

    var stepIndex: Int {
        step.index(in: steps)
    }

    var stepCount: Int {
        steps.count
    }

    var isFirstStep: Bool {
        step.previous(in: steps) == nil
    }

    var isLastStep: Bool {
        step.next(in: steps) == nil
    }

}
