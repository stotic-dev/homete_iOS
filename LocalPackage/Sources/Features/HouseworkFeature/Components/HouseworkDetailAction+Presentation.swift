//
//  HouseworkDetailAction+Presentation.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事詳細のアクションの見せ方
///
/// 文言・SF Symbol名・ボタンロールは表示の属性なので、状態だけを表す`HouseworkDetailAction`本体には
/// 持たせずView層に置く。ナビゲーションバーのボタンとメニューの両方が同じ見せ方を参照するため、
/// それぞれのView内ではなく拡張として切り出している（`HouseworkQuickAction+Presentation`と同じ方針）。
extension HouseworkDetailAction {

    var label: LocalizedStringResource {
        switch self {
        case .complete:
            .localized("完了にする")
        case .sendThanks:
            .localized("ありがとうを伝える")
        case .addThanksMessage:
            .localized("メッセージを添える")
        case .editThanksMessage:
            .localized("送ったメッセージを編集")
        case .addHelper:
            .localized("手伝った人を追加")
        case .redo:
            .localized("もう一度やった")
        case .returnToIncomplete:
            .localized("未完了に戻す")
        case .remove:
            .localized("やらない")
        }
    }

    var systemImage: String {
        switch self {
        case .complete:
            "checkmark.circle.fill"
        case .sendThanks:
            "hands.clap.fill"
        case .addThanksMessage:
            "text.bubble"
        case .editThanksMessage:
            "square.and.pencil"
        case .addHelper:
            "person.badge.plus"
        case .redo:
            "arrow.clockwise"
        case .returnToIncomplete:
            "arrow.uturn.backward"
        case .remove:
            "trash"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .remove:
            .destructive

        case .complete, .sendThanks, .addThanksMessage, .editThanksMessage, .addHelper,
             .redo, .returnToIncomplete:
            nil
        }
    }

    /// ナビゲーションバーのボタンに使うアイコン
    var navigationBarLabel: NavigationBarContentLabel {
        .symbol(systemImage, accessibilityLabel: label)
    }

}
