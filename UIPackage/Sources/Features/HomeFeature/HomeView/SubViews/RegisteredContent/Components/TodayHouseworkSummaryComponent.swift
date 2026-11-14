//
//  TodayHouseworkSummaryComponent.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/20.
//

import HomeFeatureUI
import HometeAppCore
import HometeDomain
import HometeDomainUI
import HometeModel
import HometeResources
import HometeUI
import HouseworkFeature
import HouseworkFeatureUI
import SwiftUI

/// ダッシュボードの「今日の家事サマリー」
///
/// 一覧と完了にするシートの状態は`TodayHouseworkViewModel`が持ち（doc/adr/0072）、
/// ここでは登録のシートと画面遷移を受け持つ。見た目は`TodayHouseworkSummaryContent`に任せる。
struct TodayHouseworkSummaryComponent: View {

    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.registeredContentNavigationPath) var navigationPath
    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account) var account

    @State var viewModel: TodayHouseworkViewModel
    @State var isPresentingRegister = false
    /// クイックアクションの「明日にまわす」で、確認のアラートを出している家事
    @State var postponeConfirmation: HouseworkPostponeConfirmation?
    @CommonError var commonError

    static func make() -> some View {
        TodayHouseworkSummaryLoader()
    }

    var body: some View {
        TodayHouseworkSummaryContent(
            summary: viewModel.summary,
            members: members,
            onTapRegister: { isPresentingRegister = true },
            onTapItem: { navigationPath.push(.houseworkDetail($0)) },
            onTapComplete: { viewModel.send(.completeTapped(itemId: $0.id)) },
            onTapShowMore: { navigationPath.push(.incompleteHouseworkList) },
            rowMenu: { item in
                HouseworkQuickActionMenuComponent(
                    item: item,
                    step: .dashboard,
                    // 未完了の家事だけを並べるため、ありがとうと手伝った人の追加は選ばれない
                    canAddHelper: false,
                    onSelectComplete: { viewModel.send(.completeTapped(itemId: item.id)) },
                    onSelectThanks: {},
                    onSelectAddHelper: {},
                    onRequestPostponeConfirmation: { postponeConfirmation = $0 },
                    onError: { commonError = .init(error: $0) }
                )
            }
        )
        .sheet(isPresented: $isPresentingRegister) {
            RegisterHouseworkScreen.make(
                dailyHouseworkList: .makeInitialValue(
                    selectedDate: now,
                    items: [],
                    calendar: calendar
                ),
                step: .dashboard
            )
        }
        .sheet(item: completion) { completion in
            HouseworkCompleteSheet(viewModel: completion)
        }
        .onChange(of: context) { _, context in
            viewModel.send(.contextChanged(context))
        }
        .houseworkPostponeConfirmation(
            $postponeConfirmation,
            step: .dashboard,
            onError: { commonError = .init(error: $0) }
        )
        .commonError(content: $commonError)
    }

}

private extension TodayHouseworkSummaryComponent {

    /// 一覧を組み立てるのに使う、画面の外から決まる値
    var context: TodayHouseworkViewModel.Context {
        .init(
            now: now,
            template: templateContext.templateOfDay(by: now, calendar: calendar),
            members: members,
            account: account
        )
    }

    /// 完了にするシートの表示状態。下へのスワイプで閉じたこともViewModelへ伝える
    var completion: Binding<HouseworkCompleteViewModel?> {
        .init(
            get: { viewModel.completion },
            set: { newValue in
                if newValue == nil {
                    viewModel.send(.completionDismissed)
                }
            }
        )
    }

}

/// 環境の値から`TodayHouseworkViewModel`を作って、`TodayHouseworkSummaryComponent`に渡す
private struct TodayHouseworkSummaryLoader: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account) var account

    var body: some View {
        TodayHouseworkSummaryComponent(viewModel: .init(
            context: .init(
                now: now,
                template: templateContext.templateOfDay(by: now, calendar: calendar),
                members: members,
                account: account
            ),
            houseworkListStore: houseworkListStore,
            calendar: calendar
        ))
    }

}
