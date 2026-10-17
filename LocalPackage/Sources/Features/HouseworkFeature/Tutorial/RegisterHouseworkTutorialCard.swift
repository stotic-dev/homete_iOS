//
//  RegisterHouseworkTutorialCard.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事登録シートを初めて開いたときのチュートリアルで、ステップごとに使い方を説明するカード
struct RegisterHouseworkTutorialCard: View {

    let step: RegisterHouseworkTutorialStep
    let onTapNext: () -> Void
    let onTapBack: () -> Void
    let onTapClose: () -> Void

    var body: some View {
        TutorialCard(
            step: step,
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

private extension RegisterHouseworkTutorialCard {

    var systemImage: String {
        switch step {
        case .inputSource:
            "rectangle.split.2x1"

        case .queue:
            "plus.square.on.square"

        case .saveAsFrequent:
            "star.fill"
        }
    }

    var title: LocalizedStringResource {
        switch step {
        case .inputSource:
            .localized("2つの入力方法")

        case .queue:
            .localized("まとめて登録する")

        case .saveAsFrequent:
            .localized("いつもの家事に保存する")
        }
    }

    var message: LocalizedStringResource {
        switch step {
        case .inputSource:
            .localized("「いつもの家事」では、保存しておいた家事をタップするだけで選べます。はじめての家事は「新しく入力」から名前を入れて追加できます。")

        case .queue:
            .localized("「続けて入力する」を押すと、入力した家事がたまっていきます。右上のボタンで、ためた家事をまとめて登録できます。")

        case .saveAsFrequent:
            .localized("オンにして登録すると、次からは「いつもの家事」でタップするだけで選べます。")
        }
    }

}

#Preview("RegisterHouseworkTutorialCard_入力方法", traits: .sizeThatFitsLayout) {
    RegisterHouseworkTutorialCard(step: .inputSource, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("RegisterHouseworkTutorialCard_まとめて登録", traits: .sizeThatFitsLayout) {
    RegisterHouseworkTutorialCard(step: .queue, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}

#Preview("RegisterHouseworkTutorialCard_いつもの家事に保存", traits: .sizeThatFitsLayout) {
    RegisterHouseworkTutorialCard(step: .saveAsFrequent, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .padding(.space16)
}
