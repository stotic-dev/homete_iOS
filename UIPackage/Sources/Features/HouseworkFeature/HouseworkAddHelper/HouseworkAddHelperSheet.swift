//
//  HouseworkAddHelperSheet.swift
//  LocalPackage
//

import HometeDomainUI
import HometeDomain
import HometeUI
import HouseworkFeatureUI
import SwiftUI

/// 完了した家事に手伝った人を追加するハーフモーダル
///
/// もともとの担当者はそのままにして、手伝ってくれたメンバーを足す。家事の合計ポイントは変えず、
/// 追加後の担当者で配り直す。
struct HouseworkAddHelperSheet: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account) var account
    @Environment(\.dismiss) var dismiss
    @CommonError var commonError
    @LoadingState var loadingState

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep

    var body: some View {
        NavigationStack {
            HouseworkAddHelperView(
                item: item,
                members: members,
                onTapClose: { dismiss() },
                onTapSave: { allocation in
                    loadingState.task {
                        await tappedSaveButton(allocation: allocation)
                    }
                }
            )
        }
        .presentationDragIndicator(.visible)
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonError)
        .trackScreenView(.houseworkAddHelper)
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkAddHelperSheet {

    func tappedSaveButton(allocation: HouseworkExecutorAllocation) async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            let executors = try allocation.makeExecutors()
            try await houseworkListStore.addHelpers(
                target: item.originalItem,
                executors: executors,
                cohabitantId: cohabitantId,
                step: step
            )
            dismiss()
        } catch {
            commonError = .init(error: error)
        }
    }

}
