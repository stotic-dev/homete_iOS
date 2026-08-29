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

    let selection: HouseworkSelection
    let onError: (Error) -> Void
    let onCompleted: () -> Void

    var body: some View {
        HStack(spacing: .space16) {
            ForEach(selection.availableActions) { action in
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
        .disabled(selection.targets(for: action).isEmpty)

        if action == selection.availableActions.first {
            button.subPrimaryButtonStyle()
        } else {
            button.primaryButtonStyle()
        }
    }

    func performBulk(_ action: HouseworkQuickAction) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        do {
            try await houseworkListStore.performBulk(
                action,
                on: selection.targets(for: action),
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
