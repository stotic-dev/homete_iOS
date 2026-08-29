//
//  HouseworkBulkActionBar.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

/// 複数選択モードで表示する、選択中の家事に一括でクイックアクションを適用するバー
struct HouseworkBulkActionBar: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext) var loginContext
    @Environment(\.now) var now

    let state: HouseworkState
    let selectedItems: [HouseworkBoardItem]
    let onError: (Error) -> Void
    let onCompleted: () -> Void

    var body: some View {
        HStack(spacing: .space16) {
            ForEach(bulkActions) { action in
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
            Task {
                await performBulk(action)
            }
        } label: {
            Label(action.label, systemImage: action.systemImage)
                .frame(maxWidth: .infinity)
        }
        .disabled(targets(for: action).isEmpty)

        if action == bulkActions.first {
            button.subPrimaryButtonStyle()
        } else {
            button.primaryButtonStyle()
        }
    }

}

// MARK: プレゼンテーションロジック

private extension HouseworkBulkActionBar {

    /// バーに並べるアクション
    ///
    /// 未選択のうちはタブのステータスから決まる既定のボタンを非活性で並べ、選択されたら
    /// その家事に実際に行えるアクションへ差し替える。
    var bulkActions: [HouseworkQuickAction] {
        if selectedItems.isEmpty {
            HouseworkQuickAction.actions(for: state)
        } else {
            HouseworkQuickAction.availableActions(
                for: selectedItems,
                ownUserId: loginContext.account.id
            )
        }
    }

    /// 選択項目のうち、そのアクションを実際に適用できる対象
    func targets(for action: HouseworkQuickAction) -> [HouseworkBoardItem] {
        selectedItems.filter {
            HouseworkQuickAction.actions(for: $0, ownUserId: loginContext.account.id).contains(action)
        }
    }

    func performBulk(_ action: HouseworkQuickAction) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        do {
            try await houseworkListStore.performBulk(
                action,
                on: targets(for: action),
                now: now,
                account: loginContext.account,
                cohabitantId: cohabitantId
            )
            onCompleted()
        } catch {
            onError(error)
        }
    }

}
