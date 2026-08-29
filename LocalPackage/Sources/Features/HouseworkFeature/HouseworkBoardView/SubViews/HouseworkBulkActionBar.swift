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

    var bulkActions: [HouseworkQuickAction] {
        HouseworkQuickAction.actions(for: state)
    }

    /// 選択項目のうち、そのアクションを実際に適用できる対象
    ///
    /// 承認待ちタブは自分が実施した項目（レビュー不可）が混ざりうるため、承認/再確認依頼は絞り込む。
    func targets(for action: HouseworkQuickAction) -> [HouseworkBoardItem] {
        switch action {
        case .approve, .reject:
            selectedItems.filter { $0.canReview(ownUserId: loginContext.account.id) }
        case .requestReview, .remove, .returnToIncomplete:
            selectedItems
        }
    }

    func performBulk(_ action: HouseworkQuickAction) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        let items = targets(for: action)

        do {
            for item in items {
                try await houseworkListStore.perform(
                    action,
                    on: item,
                    now: now,
                    account: loginContext.account,
                    cohabitantId: cohabitantId
                )
            }
            onCompleted()
        } catch {
            onError(error)
        }
    }

}
