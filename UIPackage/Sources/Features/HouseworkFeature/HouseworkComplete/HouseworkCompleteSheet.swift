//
//  HouseworkCompleteSheet.swift
//  LocalPackage
//

import HometeAppCore
import HometeDomain
import HometeDomainUI
import HometeResources
import HometeUI
import HouseworkFeatureUI
import SwiftUI

/// 家事を完了にするハーフモーダル
///
/// 頑張り度と、担当者（自分以外や複数人も選べる）・ポイントの配分を入力する。
/// 完了にしたら、中身をほめっとがほめる演出に切り替え、見せ終わってから閉じる。
/// 状態と操作は`HouseworkCompleteViewModel`が持ち、このViewはつなぐだけにする。
public struct HouseworkCompleteSheet: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account) var account
    @Environment(\.dismiss) var dismiss
    @Environment(\.now) var now

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep
    /// 出す側が持っているViewModel。`nil`ならこのシートの中で作る
    let viewModel: HouseworkCompleteViewModel?

    public init(item: HouseworkBoardItem, step: HouseworkAnalyticsStep) {
        self.item = item
        self.step = step
        viewModel = nil
    }

    /// 出すかどうかを出す側のViewModelが持つときに使う
    public init(viewModel: HouseworkCompleteViewModel) {
        item = viewModel.item
        step = .dashboard
        self.viewModel = viewModel
    }

    public var body: some View {
        if let viewModel {
            HouseworkCompleteSheetContent(viewModel: viewModel)
        } else {
            OwnedHouseworkCompleteSheet(viewModel: .init(
                item: item,
                step: step,
                members: members,
                account: account,
                houseworkListStore: houseworkListStore,
                now: { [now] in now },
                onFinish: { [dismiss] _ in dismiss() }
            ))
        }
    }

}

/// シートの中でViewModelを作って持つ
private struct OwnedHouseworkCompleteSheet: View {

    @State var viewModel: HouseworkCompleteViewModel

    var body: some View {
        HouseworkCompleteSheetContent(viewModel: viewModel)
    }

}

private struct HouseworkCompleteSheetContent: View {

    @State var praise: HometteCompletionPraise?

    let viewModel: HouseworkCompleteViewModel

    var body: some View {
        NavigationStack {
            HouseworkCompleteView(
                selectableMembers: viewModel.selectableMembers,
                allocation: .init(
                    get: { viewModel.state.allocation },
                    set: { viewModel.send(.allocationChanged($0)) }
                ),
                isExpandedAllocation: .init(
                    get: { viewModel.state.isExpandedAllocation },
                    set: { viewModel.send(.allocationExpandedChanged($0)) }
                ),
                praise: praise,
                canComplete: viewModel.state.canComplete,
                onTapClose: { viewModel.send(.closeTapped) },
                onTapComplete: { viewModel.send(.completeTapped) },
                onFinishPraise: { viewModel.send(.praiseFinished) }
            )
        }
        .presentationDragIndicator(.visible)
        .fullScreenLoadingIndicator(LoadingStateStore(isLoading: viewModel.state.isCompleting))
        .commonError(content: errorContent)
        // ほめる文言は毎回ランダムに選ぶので、完了にできた時点で1回だけ決める
        .onChange(of: viewModel.state.completedPoint) { _, point in
            guard let point else { return }
            praise = .init(houseworkTitle: viewModel.item.originalItem.title, point: point)
        }
        .trackScreenView(.houseworkComplete)
    }

}

private extension HouseworkCompleteSheetContent {

    var errorContent: Binding<DomainErrorAlertContent> {
        .init(
            get: { viewModel.state.error.map { .init(error: $0) } ?? .initial },
            set: { content in
                if !content.isPresenting {
                    viewModel.send(.errorDismissed)
                }
            }
        )
    }

}
