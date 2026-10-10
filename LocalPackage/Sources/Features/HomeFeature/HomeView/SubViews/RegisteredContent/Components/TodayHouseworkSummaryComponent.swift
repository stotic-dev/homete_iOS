//
//  TodayHouseworkSummaryComponent.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/20.
//

import HometeDomain
import HometeResources
import HometeUI
import HouseworkFeature
import SwiftUI

/// ダッシュボードの「今日の家事サマリー」
///
/// Storeから今日のサマリーを組み立て、登録・完了のシートと画面遷移を受け持つ。
/// 見た目は`TodayHouseworkSummaryContent`に任せる。
struct TodayHouseworkSummaryComponent: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.now) var now
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.registeredContentNavigationPath) var navigationPath
    @Environment(\.cohabitantMembers) var members

    @State var isPresentingRegister = false
    /// クイックアクションの「完了にする」で、担当者を選ぶハーフモーダルを出している家事
    @State var completingItem: HouseworkBoardItem?
    @CommonError var commonError

    static func make() -> some View {
        TodayHouseworkSummaryComponent()
    }

    var body: some View {
        TodayHouseworkSummaryContent(
            summary: TodayHouseworkSummary.make(
                storedAllItems: houseworkListStore.items,
                template: templateContext.templateOfDay(by: now, calendar: calendar),
                now: now,
                calendar: calendar,
                storagePolicy: storagePolicy
            ),
            members: members,
            onTapRegister: { isPresentingRegister = true },
            onTapItem: { navigationPath.push(.houseworkDetail($0)) },
            onTapComplete: { completingItem = $0 },
            onTapShowMore: { navigationPath.push(.incompleteHouseworkList) },
            rowMenu: { item in
                HouseworkQuickActionMenuContent(
                    item: item,
                    step: .dashboard,
                    // 未完了の家事だけを並べるため、ありがとうと手伝った人の追加は選ばれない
                    canAddHelper: false,
                    onSelectComplete: { completingItem = item },
                    onSelectThanks: {},
                    onSelectAddHelper: {},
                    onError: { commonError = .init(error: $0) }
                )
            }
        )
        .sheet(isPresented: $isPresentingRegister) {
            RegisterHouseworkView.make(
                dailyHouseworkList: .makeInitialValue(
                    selectedDate: now,
                    items: [],
                    calendar: calendar,
                    storagePolicy: storagePolicy
                ),
                step: .dashboard
            )
        }
        .sheet(item: $completingItem) { item in
            HouseworkCompleteSheet(item: item, step: .dashboard)
        }
        .commonError(content: $commonError)
    }

}
