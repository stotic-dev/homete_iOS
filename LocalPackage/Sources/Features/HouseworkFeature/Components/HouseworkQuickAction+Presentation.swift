//
//  HouseworkQuickAction+Presentation.swift
//  LocalPackage
//

import SwiftUI

/// クイックアクションの見せ方
///
/// 文言・SF Symbol名・ボタンロールは表示の属性なので、状態だけを表す`HouseworkQuickAction`本体には
/// 持たせずView層に置く。メニュー・ナビゲーションバーと複数のViewが同じ見せ方を参照するため、
/// それぞれのView内ではなく拡張として切り出している。
extension HouseworkQuickAction {

    var label: String {
        switch self {
        case .complete:
            "完了にする"
        case .remove:
            "やらない"
        case .sendThanks:
            "ありがとう"
        case .addHelper:
            "手伝った人を追加"
        case .redo:
            "もう一度やった"
        case .returnToIncomplete:
            "未完了に戻す"
        }
    }

    /// ありがとうは、家事セルで伝えたかどうかを示すハートと同じ図柄にして、同じ操作だと分かるようにする
    var systemImage: String {
        switch self {
        case .complete:
            "checkmark.circle.fill"
        case .remove:
            "trash"
        case .sendThanks:
            "heart"
        case .addHelper:
            "person.badge.plus"
        case .redo:
            "arrow.clockwise"
        case .returnToIncomplete:
            "arrow.uturn.backward"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .remove:
            .destructive
        case .complete, .sendThanks, .addHelper, .redo, .returnToIncomplete:
            nil
        }
    }

}
