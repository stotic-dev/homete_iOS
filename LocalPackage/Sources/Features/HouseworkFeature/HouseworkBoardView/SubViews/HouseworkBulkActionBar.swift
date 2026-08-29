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
        .disabled(selectedItems.isEmpty)

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

    func performBulk(_ action: HouseworkQuickAction) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        let targets: [HouseworkBoardItem] = switch action {
        case .approve, .reject:
            selectedItems.filter { $0.canReview(ownUserId: loginContext.account.id) }
        case .requestReview, .remove, .returnToIncomplete:
            selectedItems
        }

        do {
            for item in targets {
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
