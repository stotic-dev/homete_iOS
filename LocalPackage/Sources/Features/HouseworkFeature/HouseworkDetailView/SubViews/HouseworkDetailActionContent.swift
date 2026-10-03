//
//  HouseworkDetailActionContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/16.
//

import HometeUI
import SwiftUI

/// 家事詳細のナビゲーションバー右側に並べるアクション
///
/// アクションが増えて画面下のボタンが読みづらくなったため、よく使う1つだけを単独のアイコンボタンにして、
/// 残りは「その他」のメニューに入れる。どれを単独で出すかは`HouseworkDetailAction.isPrimary`で決まり、
/// このViewは渡されたアクションを描いてタップを伝えるだけに留める。
struct HouseworkDetailActionContent: View {

    /// 単独のアイコンボタンとして出すアクション。無ければ「その他」だけになる
    let primaryAction: HouseworkDetailAction?
    /// 「その他」のメニューに入れるアクション。空ならメニューを出さない
    let menuActions: [HouseworkDetailAction]
    let onTap: (HouseworkDetailAction) -> Void

    var body: some View {
        HStack(spacing: .zero) {
            if let primaryAction {
                NavigationBarButton(label: primaryAction.navigationBarLabel) {
                    onTap(primaryAction)
                }
            }
            if !menuActions.isEmpty {
                NavigationBarMenuButton(label: .more) {
                    HouseworkDetailActionMenuContent(actions: menuActions, onTap: onTap)
                }
            }
        }
    }

}

#if DEBUG
#Preview("HouseworkDetailActionContent_未完了", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        primaryAction: .complete,
        menuActions: [.remove],
        onTap: { _ in }
    )
}

#Preview("HouseworkDetailActionContent_完了_ありがとうを伝える", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        primaryAction: .sendThanks,
        menuActions: [.addHelper, .redo, .returnToIncomplete, .remove],
        onTap: { _ in }
    )
}

#Preview("HouseworkDetailActionContent_完了_メッセージを添える", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        primaryAction: .addThanksMessage,
        menuActions: [.addHelper, .redo, .returnToIncomplete, .remove],
        onTap: { _ in }
    )
}

#Preview("HouseworkDetailActionContent_完了_メッセージを編集", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        primaryAction: .editThanksMessage,
        menuActions: [.addHelper, .redo, .returnToIncomplete, .remove],
        onTap: { _ in }
    )
}

#Preview("HouseworkDetailActionContent_完了_自分が終えた家事", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        primaryAction: nil,
        menuActions: [.addHelper, .redo, .returnToIncomplete, .remove],
        onTap: { _ in }
    )
}
#endif
