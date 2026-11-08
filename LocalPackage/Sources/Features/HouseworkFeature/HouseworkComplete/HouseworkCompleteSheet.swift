//
//  HouseworkCompleteSheet.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import HometeUI
import HouseworkFeatureUI
import SwiftUI

/// 家事を完了にするハーフモーダル
///
/// 頑張り度と、担当者（自分以外や複数人も選べる）・ポイントの配分を入力する。
/// 完了にしたら、中身をほめっとがほめる演出に切り替え、見せ終わってから閉じる。
public struct HouseworkCompleteSheet: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account) var account
    @Environment(\.dismiss) var dismiss
    @Environment(\.now) var now
    @CommonError var commonError
    @LoadingState var loadingState

    /// 完了にできたときの、ほめっとがほめる内容。入ると中身を演出に切り替える
    @State var praise: HometteCompletionPraise?

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep

    public init(item: HouseworkBoardItem, step: HouseworkAnalyticsStep) {
        self.item = item
        self.step = step
    }

    public var body: some View {
        NavigationStack {
            HouseworkCompleteView(
                item: item,
                members: members,
                account: account,
                praise: praise,
                onTapClose: { dismiss() },
                onTapComplete: { allocation in
                    loadingState.task {
                        await tappedCompleteButton(allocation: allocation)
                    }
                },
                onFinishPraise: { dismiss() }
            )
        }
        .presentationDragIndicator(.visible)
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonError)
        .trackScreenView(.houseworkComplete)
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkCompleteSheet {

    func userName(_ userId: String) -> String {
        members.userName(userId) ?? (userId == account.id ? account.userName : "")
    }

    func tappedCompleteButton(allocation: HouseworkExecutorAllocation) async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            let executors = try allocation.makeExecutors()
            try await houseworkListStore.complete(
                target: item.originalItem,
                now: now,
                reporter: account,
                executors: executors,
                effort: allocation.effort,
                executorNames: executors.map { userName($0.userId) },
                comment: "",
                cohabitantId: cohabitantId,
                isRegistered: item.isRegistered,
                step: step
            )
            praise = .init(
                houseworkTitle: item.originalItem.title,
                point: executors.reduce(0) { $0 + $1.point }
            )
        } catch {
            commonError = .init(error: error)
        }
    }

}
