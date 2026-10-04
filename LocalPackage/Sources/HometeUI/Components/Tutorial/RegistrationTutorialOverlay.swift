//
//  RegistrationTutorialOverlay.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// グループ登録の直後に、タブの上に重ねて導線を案内するチュートリアル
///
/// 操作はさせず、ステップごとに「どこで何ができるか」を説明するだけにとどめる。
/// タブバーの項目の位置はシステムが決めて取得できないため、吹き出しで指す代わりに、
/// タブと同じアイコンと「どこから開けるか」の一文で場所を伝える。
public struct RegistrationTutorialOverlay: View {

    let step: RegistrationTutorialStep
    let onTapNext: () -> Void
    let onTapClose: () -> Void

    public init(
        step: RegistrationTutorialStep,
        onTapNext: @escaping () -> Void,
        onTapClose: @escaping () -> Void
    ) {
        self.step = step
        self.onTapNext = onTapNext
        self.onTapClose = onTapClose
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 後ろの画面を触らせないよう、タップを受け止めるだけにする
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(.rect)
                .onTapGesture {}
                .accessibilityHidden(true)
            card
                .padding(.horizontal, .space16)
                // タブバーの上に置き、どのタブの話かを見比べられるようにする
                .padding(.bottom, .space64)
        }
    }

}

// MARK: UI定義

private extension RegistrationTutorialOverlay {

    var card: some View {
        VStack(alignment: .leading, spacing: .space16) {
            header
            HStack(alignment: .top, spacing: .space16) {
                icon
                VStack(alignment: .leading, spacing: .space8) {
                    Text(title)
                        .font(with: .headLineS)
                        .foregroundStyle(.onSurface)
                    Text(message)
                        .font(with: .body)
                        .foregroundStyle(.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                    Label(location, systemImage: "hand.point.up.left")
                        .font(with: .caption)
                        .foregroundStyle(.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button(isLastStep ? "はじめる" : "次へ", action: onTapNext)
                .primaryButtonStyle()
        }
        .sectionCardStyle()
        .id(step)
        .transition(.opacity)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    var header: some View {
        HStack {
            Text("\(step.index + 1) / \(RegistrationTutorialStep.allCases.count)")
                .font(with: .boldCaption)
                .foregroundStyle(.onSurfaceVariant)
                .accessibilityLabel("\(RegistrationTutorialStep.allCases.count)つ中\(step.index + 1)つ目")
            Spacer()
            Button("閉じる", action: onTapClose)
                .font(with: .caption)
                .foregroundStyle(.onSurfaceVariant)
        }
    }

    var icon: some View {
        Image(systemName: systemImage)
            .font(.title2)
            .foregroundStyle(iconForegroundStyle)
            .frame(width: .space48, height: .space48)
            .background {
                Circle()
                    .fill(.surface)
            }
            .accessibilityHidden(true)
    }

}

// MARK: 表示の属性

private extension RegistrationTutorialOverlay {

    var isLastStep: Bool {
        step.next == nil
    }

    var systemImage: String {
        switch step {
        case .dashboard:
            "list.bullet.clipboard.fill"
        case .housework:
            "person.2.arrow.trianglehead.counterclockwise"
        case .thanks:
            "heart.fill"
        case .houseworkTemplate:
            "list.bullet.rectangle"
        }
    }

    var iconForegroundStyle: Color {
        switch step {
        case .thanks:
            .thanksHeart
        case .dashboard, .housework, .houseworkTemplate:
            .primary3
        }
    }

    var title: LocalizedStringKey {
        switch step {
        case .dashboard:
            "ダッシュボード"
        case .housework:
            "家事"
        case .thanks:
            "ありがとうを伝えましょう"
        case .houseworkTemplate:
            "家事テンプレート"
        }
    }

    var message: LocalizedStringKey {
        switch step {
        case .dashboard:
            "今日の家事がどこまで進んだかと、メンバーごとの貢献度をひと目で確認できます。"
        case .housework:
            "やる家事を登録しておき、終わったら完了にできます。誰がどの家事をしたかが記録されます。"
        case .thanks:
            "パートナーが完了した家事にありがとうを送ると、相手に通知が届きます。小さな家事にも、ひと言伝えてみましょう。"
        case .houseworkTemplate:
            "毎週やる家事を曜日ごとに登録しておくと、家事ボードに自動で並びます。"
        }
    }

    var location: LocalizedStringKey {
        switch step {
        case .dashboard:
            "画面下の「ダッシュボード」タブから開けます"
        case .housework:
            "画面下の「家事」タブから開けます"
        case .thanks:
            "家事タブの「完了」に並んだ家事のハートから送れます"
        case .houseworkTemplate:
            "家事タブの右上のボタンから設定できます"
        }
    }

}

#Preview("RegistrationTutorialOverlay_ダッシュボード") {
    RegistrationTutorialOverlay(step: .dashboard, onTapNext: {}, onTapClose: {})
}

#Preview("RegistrationTutorialOverlay_家事") {
    RegistrationTutorialOverlay(step: .housework, onTapNext: {}, onTapClose: {})
}

#Preview("RegistrationTutorialOverlay_ありがとう") {
    RegistrationTutorialOverlay(step: .thanks, onTapNext: {}, onTapClose: {})
}

#Preview("RegistrationTutorialOverlay_家事テンプレート") {
    RegistrationTutorialOverlay(step: .houseworkTemplate, onTapNext: {}, onTapClose: {})
}
