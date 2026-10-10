//
//  HouseworkBulkActionToolbarContent.swift
//  homete
//

import HometeUI
import SwiftUI

/// 複数選択モードのときにナビゲーションバーの右側へ並べる、一括操作のアイコンボタン
///
/// `.trailingToolbarItem { }` の中身として使う。
/// 何を並べるか・実行できるかの判断は呼び出し側（`HouseworkSelection`を持つView）が行い、
/// このコンポーネントは渡されたアクションを描画してタップを伝えるだけに留める。
struct HouseworkBulkActionToolbarContent: View {

    /// 並べるアクション。何も選択されていない間は空で、ボタンを1つも出さない
    let actions: [HouseworkQuickAction]
    let onTap: (HouseworkQuickAction) -> Void

    var body: some View {
        HStack(spacing: .space8) {
            ForEach(actions) { action in
                actionButton(action)
            }
        }
    }

}

private extension HouseworkBulkActionToolbarContent {

    func actionButton(_ action: HouseworkQuickAction) -> some View {
        Button {
            onTap(action)
        } label: {
            Image(systemName: action.systemImage)
                .padding(.space8)
                .foregroundStyle(foregroundStyle(action))
        }
        // アイコンだけでは何をするボタンか読み上げられないため、メニューと同じ文言を添える
        .accessibilityLabel(action.label)
    }

    /// 取り消しにあたる操作だけ、赤系の色で他のアクションと取り違えないようにする
    func foregroundStyle(_ action: HouseworkQuickAction) -> Color {
        action.role == .destructive ? .destructive : .onSurface
    }

}

#if DEBUG
#Preview("HouseworkBulkActionToolbarContent_未完了", traits: .sizeThatFitsLayout) {
    HouseworkBulkActionToolbarContent(
        actions: [.complete, .remove],
        onTap: { _ in }
    )
}

#Preview("HouseworkBulkActionToolbarContent_完了_実施者以外", traits: .sizeThatFitsLayout) {
    HouseworkBulkActionToolbarContent(
        actions: [.sendThanks, .returnToIncomplete],
        onTap: { _ in }
    )
}

#Preview("HouseworkBulkActionToolbarContent_完了_実施者本人", traits: .sizeThatFitsLayout) {
    HouseworkBulkActionToolbarContent(
        actions: [.returnToIncomplete],
        onTap: { _ in }
    )
}
#endif
