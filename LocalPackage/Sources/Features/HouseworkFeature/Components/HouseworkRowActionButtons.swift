//
//  HouseworkRowActionButtons.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事の行の右端に並べる、完了とクイックアクションのボタン
///
/// 長押ししないとクイックアクションに気づけなかったため、同じ操作をタップでも開けるようにしたもの。
/// `HouseBoardListRow`が行のタップと競合しない位置に並べる。
///
/// 完了は入力用のハーフモーダルを出すため、その場では実行せず`onTapComplete`で呼び出し元に伝える
/// （`Menu`の中からはシートを出せない。`.contextMenu`と同じ制約）。
struct HouseworkRowActionButtons<MenuContent: View>: View {

    /// 完了ボタンを出すかどうか（未完了の家事だけ）
    let showsCompleteButton: Bool
    /// その他ボタンを出すかどうか（メニューに出せるアクションが1つも無いときは出さない）
    let showsMoreButton: Bool
    let onTapComplete: () -> Void
    /// その他ボタンのメニューの中身。`HouseworkQuickActionMenuContent`を渡す
    @ViewBuilder let menuContent: () -> MenuContent

    var body: some View {
        HStack(spacing: .zero) {
            // 一番よく使う操作なので、メニューを開かずワンタップで完了のモーダルへ入れるようにする
            if showsCompleteButton {
                completeButton()
            }
            if showsMoreButton {
                moreButton()
            }
        }
    }

}

private extension HouseworkRowActionButtons {

    func completeButton() -> some View {
        Button(action: onTapComplete) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 22))
                .foregroundStyle(.fillAccent)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(.localized("完了にする"))
    }

    func moreButton() -> some View {
        Menu {
            menuContent()
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 22))
                .foregroundStyle(.textSecondary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(.localized("その他の操作"))
    }

}

#if DEBUG
#Preview("HouseworkRowActionButtons_完了とその他", traits: .sizeThatFitsLayout) {
    HouseworkRowActionButtons(
        showsCompleteButton: true,
        showsMoreButton: true,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

#Preview("HouseworkRowActionButtons_その他のみ", traits: .sizeThatFitsLayout) {
    HouseworkRowActionButtons(
        showsCompleteButton: false,
        showsMoreButton: true,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}
#endif
