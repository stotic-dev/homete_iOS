//
//  HouseworkTemplateTutorialCard.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事テンプレート画面を初めて開いたときのチュートリアルで、ステップごとに使い方を説明するカード
struct HouseworkTemplateTutorialCard: View {

    let step: HouseworkTemplateTutorialStep
    /// 今回出すステップ。テンプレートを作成済みなら作成のステップを除く
    var steps = HouseworkTemplateTutorialStep.allCases
    let onTapNext: () -> Void
    let onTapBack: () -> Void
    let onTapClose: () -> Void

    var body: some View {
        TutorialCard(
            step: step,
            steps: steps,
            systemImage: systemImage,
            iconForegroundStyle: .textAccent,
            title: title,
            message: message,
            onTapNext: onTapNext,
            onTapBack: onTapBack,
            onTapClose: onTapClose
        )
    }

}

// MARK: 表示の属性

private extension HouseworkTemplateTutorialCard {

    var systemImage: String {
        switch step {
        case .create:
            "list.bullet.rectangle"

        case .addItem:
            "plus.circle.fill"

        case .autoPlacement:
            "calendar"

        case .save:
            "checkmark.circle.fill"
        }
    }

    var title: LocalizedStringResource {
        switch step {
        case .create:
            .localized("テンプレートを作る")

        case .addItem:
            .localized("家事を追加する")

        case .autoPlacement:
            .localized("家事ボードに自動で並ぶ")

        case .save:
            .localized("保存して反映する")
        }
    }

    var message: LocalizedStringResource {
        switch step {
        case .create:
            .localized("はじめに「テンプレートを作成する」を押すと、くり返す家事を登録できるようになります。")

        case .addItem:
            .localized("＋から、くり返す曜日や毎月の日にちを選んで家事を追加できます。")

        case .autoPlacement:
            .localized("登録した家事は、その曜日やその日の家事ボードに自動で並びます。毎回登録しなくて済みます。")

        case .save:
            .localized("追加や変更は、右上の✓で保存するまで家事ボードに反映されません。保存すると、パートナーにも共有されます。")
        }
    }

}

#Preview("HouseworkTemplateTutorialCard_作成", traits: .sizeThatFitsLayout) {
    HouseworkTemplateTutorialCard(step: .create, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("HouseworkTemplateTutorialCard_追加", traits: .sizeThatFitsLayout) {
    HouseworkTemplateTutorialCard(step: .addItem, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("HouseworkTemplateTutorialCard_作成済みで追加", traits: .sizeThatFitsLayout) {
    HouseworkTemplateTutorialCard(
        step: .addItem,
        steps: [.addItem, .autoPlacement, .save],
        onTapNext: {},
        onTapBack: {},
        onTapClose: {}
    )
    .padding(.space16)
}

#Preview("HouseworkTemplateTutorialCard_自動で並ぶ", traits: .sizeThatFitsLayout) {
    HouseworkTemplateTutorialCard(step: .autoPlacement, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("HouseworkTemplateTutorialCard_保存", traits: .sizeThatFitsLayout) {
    HouseworkTemplateTutorialCard(step: .save, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}
