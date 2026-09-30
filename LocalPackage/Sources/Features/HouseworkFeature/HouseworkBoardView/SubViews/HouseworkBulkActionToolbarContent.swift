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

    /// 並べるアクション
    let actions: [HouseworkQuickAction]
    /// アクションを実行できるかどうか（何も選択されていない間は非活性で見せる）
    let isEnabled: Bool
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
        .disabled(!isEnabled)
        // アイコンだけでは何をするボタンか読み上げられないため、メニューと同じ文言を添える
        .accessibilityLabel(action.label)
    }

    /// 取り消しにあたる操作だけ、赤系の色で他のアクションと取り違えないようにする
    func foregroundStyle(_ action: HouseworkQuickAction) -> Color {
        action.role == .destructive ? .destructive : .onSurface
    }

}

#if DEBUG
#Preview("HouseworkBulkActionToolbarContent_未完了_未選択", traits: .sizeThatFitsLayout) {
    HouseworkBulkActionToolbarContent(
        actions: [.complete, .remove],
        isEnabled: false,
        onTap: { _ in }
    )
}

#Preview("HouseworkBulkActionToolbarContent_未完了_選択あり", traits: .sizeThatFitsLayout) {
    HouseworkBulkActionToolbarContent(
        actions: [.complete, .remove],
        isEnabled: true,
        onTap: { _ in }
    )
}

#Preview("HouseworkBulkActionToolbarContent_完了_実施者以外", traits: .sizeThatFitsLayout) {
    HouseworkBulkActionToolbarContent(
        actions: [.sendThanks, .returnToIncomplete],
        isEnabled: true,
        onTap: { _ in }
    )
}

#Preview("HouseworkBulkActionToolbarContent_完了_実施者本人", traits: .sizeThatFitsLayout) {
    HouseworkBulkActionToolbarContent(
        actions: [.returnToIncomplete],
        isEnabled: true,
        onTap: { _ in }
    )
}
#endif
