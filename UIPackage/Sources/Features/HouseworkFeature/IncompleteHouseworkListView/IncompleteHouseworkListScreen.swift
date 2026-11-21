//
//  IncompleteHouseworkListScreen.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import HometeDomainUI
import HometeAppCore
import HometeDomain
import HometeUI
import HouseworkFeatureUI
import SwiftUI

public struct IncompleteHouseworkListScreen: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(HouseworkListStore.self) var houseworkListStore

    @CommonError var commonError
    /// クイックアクションの「完了にする」で、担当者を選ぶハーフモーダルを出している家事
    @State var completingItem: HouseworkBoardItem?
    /// クイックアクションの「明日にまわす」で、確認のアラートを出している家事
    @State var postponeConfirmation: HouseworkPostponeConfirmation?

    /// 行をタップしたときの処理。家事詳細への遷移は、ナビゲーションを持つ呼び出し元に任せる
    let onSelectItem: (HouseworkBoardItem) -> Void

    public static func make(onSelectItem: @escaping (HouseworkBoardItem) -> Void) -> some View {
        IncompleteHouseworkListScreen(onSelectItem: onSelectItem)
    }

    public var body: some View {
        IncompleteHouseworkListView(
            summary: TodayHouseworkSummary.make(
                storedAllItems: houseworkListStore.items,
                template: templateContext.templateOfDay(by: now, calendar: calendar),
                now: now,
                calendar: calendar
            ),
            onSelectItem: onSelectItem,
            onTapComplete: { item in completingItem = item },
            rowMenu: { item in quickActionMenu(item) }
        )
        .sheet(item: $completingItem) { item in
            HouseworkCompleteSheet(item: item, step: .dashboard)
        }
        .houseworkPostponeConfirmation(
            $postponeConfirmation,
            step: .dashboard,
            onError: { commonError = .init(error: $0) }
        )
        .commonError(content: $commonError)
        .trackScreenView(.incompleteHouseworkList)
    }

}

private extension IncompleteHouseworkListScreen {

    /// 長押しのメニューと、その他ボタンのメニューで同じ中身を出す
    func quickActionMenu(_ item: HouseworkBoardItem) -> some View {
        HouseworkQuickActionMenuComponent(
            item: item,
            step: .dashboard,
            // 未完了の家事だけを並べるため、ありがとうと手伝った人の追加は選ばれない
            canAddHelper: false,
            onSelectComplete: { completingItem = item },
            onSelectThanks: {},
            onSelectAddHelper: {},
            onRequestPostponeConfirmation: { postponeConfirmation = $0 },
            onError: { commonError = .init(error: $0) }
        )
    }

}
