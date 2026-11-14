//
//  RegistrationTutorialCard.swift
//  LocalPackage
//

import HometeModel
import SwiftUI

/// グループ登録の直後のチュートリアルで、ステップごとに「どこで何ができるか」を説明するカード
///
/// タブバーの項目は位置を取得できず切り抜けないため、
/// タブと同じアイコンと「どこから開けるか」の一文で場所を伝える。
public struct RegistrationTutorialCard: View {

    let step: RegistrationTutorialStep
    let onTapNext: () -> Void
    let onTapBack: () -> Void
    let onTapClose: () -> Void

    public init(
        step: RegistrationTutorialStep,
        onTapNext: @escaping () -> Void,
        onTapBack: @escaping () -> Void,
        onTapClose: @escaping () -> Void
    ) {
        self.step = step
        self.onTapNext = onTapNext
        self.onTapBack = onTapBack
        self.onTapClose = onTapClose
    }

    public var body: some View {
        TutorialCard(
            step: step,
            systemImage: systemImage,
            iconForegroundStyle: iconForegroundStyle,
            title: title,
            message: message,
            location: location,
            onTapNext: onTapNext,
            onTapBack: onTapBack,
            onTapClose: onTapClose
        )
    }

}

// MARK: 表示の属性

private extension RegistrationTutorialCard {

    var systemImage: String {
        switch step {
        case .dashboard:
            "list.bullet.clipboard.fill"

        case .housework:
            "person.2.arrow.trianglehead.counterclockwise"

        case .houseworkComplete:
            "checkmark.circle.fill"

        case .thanks:
            "heart.fill"

        case .bulkAction:
            "checklist"

        case .houseworkTemplate:
            "list.bullet.rectangle"
        }
    }

    var iconForegroundStyle: Color {
        switch step {
        case .thanks:
            .fillThanks

        case .dashboard, .housework, .houseworkComplete, .bulkAction, .houseworkTemplate:
            .textAccent
        }
    }

    var title: LocalizedStringResource {
        switch step {
        case .dashboard:
            .localized("ダッシュボード")

        case .housework:
            .localized("家事")

        case .houseworkComplete:
            .localized("家事を完了にする")

        case .thanks:
            .localized("ありがとうを伝える")

        case .bulkAction:
            .localized("まとめて操作する")

        case .houseworkTemplate:
            .localized("家事テンプレート")
        }
    }

    var message: LocalizedStringResource {
        switch step {
        case .dashboard:
            .localized("今日の家事がどこまで進んだかと、メンバーごとのがんばりをひと目で確認できます。")

        case .housework:
            .localized("＋ボタンから、やる家事を登録しておけます。")

        case .houseworkComplete:
            .localized("終わった家事は、行の右にある✓ボタンから完了にできます。誰がどの家事をしたかが記録されます。「…」ボタンからは、やらないにするなどほかの操作もできます。")

        case .thanks:
            .localized("パートナーが完了した家事にありがとうを送ると、相手に通知が届きます。小さな家事にも、ひと言添えてみませんか。")

        case .bulkAction:
            .localized("「選択」から家事を複数選ぶと、まとめて完了にしたり、ありがとうを伝えたりできます。")

        case .houseworkTemplate:
            .localized("毎週やる家事を曜日ごとに登録しておくと、家事ボードに自動で並びます。")
        }
    }

    var location: LocalizedStringResource {
        switch step {
        case .dashboard:
            .localized("画面下の「ダッシュボード」タブから開けます")

        case .housework:
            .localized("画面下の「家事」タブから開けます")

        case .houseworkComplete:
            .localized("家事タブの「未完了」に並んだ家事から操作できます")

        case .thanks:
            .localized("家事タブの「完了」に並んだ家事のハートから送れます")

        case .bulkAction:
            .localized("家事タブの右上の「選択」から使えます")

        case .houseworkTemplate:
            .localized("家事タブの右上のボタンから設定できます")
        }
    }

}

#Preview("RegistrationTutorialCard_ダッシュボード", traits: .sizeThatFitsLayout) {
    RegistrationTutorialCard(step: .dashboard, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("RegistrationTutorialCard_家事", traits: .sizeThatFitsLayout) {
    RegistrationTutorialCard(step: .housework, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("RegistrationTutorialCard_家事の完了", traits: .sizeThatFitsLayout) {
    RegistrationTutorialCard(step: .houseworkComplete, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("RegistrationTutorialCard_ありがとう", traits: .sizeThatFitsLayout) {
    RegistrationTutorialCard(step: .thanks, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("RegistrationTutorialCard_まとめて操作", traits: .sizeThatFitsLayout) {
    RegistrationTutorialCard(step: .bulkAction, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("RegistrationTutorialCard_家事テンプレート", traits: .sizeThatFitsLayout) {
    RegistrationTutorialCard(step: .houseworkTemplate, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}
