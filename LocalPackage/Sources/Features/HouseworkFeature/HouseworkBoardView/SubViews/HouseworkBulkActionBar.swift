//
//  HouseworkBulkActionBar.swift
//  homete
//

import HometeUI
import SwiftUI

/// 複数選択モードで表示する、選択中の家事に一括でクイックアクションを適用するバー
///
/// 何を並べるか・実行できるかの判断は呼び出し側（`HouseworkSelection`を持つView）が行い、
/// このコンポーネントは渡されたアクションを描画してタップを伝えるだけに留める。
struct HouseworkBulkActionBar: View {

    /// 並べるアクション
    let actions: [HouseworkQuickAction]
    /// アクションを実行できるかどうか（何も選択されていない間は非活性で見せる）
    let isEnabled: Bool
    let onTap: (HouseworkQuickAction) -> Void

    var body: some View {
        HStack(spacing: .space16) {
            ForEach(actions) { action in
                actionButton(action)
            }
        }
        .padding(.space16)
        .background(.surface)
    }

}

private extension HouseworkBulkActionBar {

    @ViewBuilder
    func actionButton(_ action: HouseworkQuickAction) -> some View {
        let button = Button {
            onTap(action)
        } label: {
            Label(action.label, systemImage: action.systemImage)
                .frame(maxWidth: .infinity)
        }
        .disabled(!isEnabled)

        if action == actions.first {
            button.subPrimaryButtonStyle()
        } else {
            button.primaryButtonStyle()
        }
    }

}
