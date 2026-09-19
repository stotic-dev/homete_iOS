//
//  HouseworkBoardScreen.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/09.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct HouseworkBoardScreen: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.appDependencies.houseworkManager) var houseworkManager
    @Environment(\.loginContext.account.cohabitantId) var cohabitantId

    @State var houseworkBoardList: HouseworkBoardList = .init(items: [])
    @State var dateList = HouseworkDateList()

    let houseworkListStore: HouseworkListStore?
    let houseworkTemplateListStore: HouseworkTemplateListStore?

    public static func make(
        houseworkListStore: HouseworkListStore?,
        houseworkTemplateListStore: HouseworkTemplateListStore?
    ) -> some View {
        HouseworkBoardScreen(
            houseworkListStore: houseworkListStore,
            houseworkTemplateListStore: houseworkTemplateListStore
        )
    }

    public var body: some View {
        if let houseworkListStore {
            HouseworkBoardView(
                houseworkBoardList: $houseworkBoardList,
                dateList: $dateList,
                loadFailure: loadFailure(of: houseworkListStore),
                onUpdateHouseboardList: {
                    updateHouseboardList(with: houseworkListStore)
                },
                onRetry: {
                    await retry()
                }
            )
            .environment(houseworkListStore)
            .environment(houseworkTemplateListStore)
            .onAppear {
                withAnimation {
                    onAppeare(with: houseworkListStore)
                }
            }
            // プランが確定・変化したタイミングで日付リストの選択可能範囲を組み直す
            .task(id: storagePolicy) {
                rebuildDateList()
            }
        } else {
            // TODO: グループ登録前は利用できない旨の空表示を出す
            ContentUnavailableView(
                "グループの登録または参加を行うと、家事の管理ができるようになります。",
                systemImage: ""
            )
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkBoardScreen {

    func onAppeare(with store: HouseworkListStore) {
        updateHouseboardList(with: store)
    }

    /// 家事の購読が失敗している場合に、エラー表示に使う内容を返す
    func loadFailure(of store: HouseworkListStore) -> DomainError? {
        guard case let .failed(error) = store.loadState else { return nil }
        return error
    }

    /// 家事の購読をやり直す
    /// - Note: `HouseworkManager`のリスナーは失敗時に購読が止まるため、リスナーを張り直す
    ///         `setupObserver`の再実行で復帰させる。
    func retry() async {
        guard let cohabitantId else { return }
        await houseworkManager.setupObserver(
            currentTime: now,
            cohabitantId: cohabitantId,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
    }

    func rebuildDateList() {
        dateList = .init(
            anchorDate: now,
            selectedDate: dateList.selectedDate,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
    }

    func updateHouseboardList(with store: HouseworkListStore) {
        let selectedDate = dateList.selectedDate
        houseworkBoardList = .init(
            dailyList: store.items.value,
            selectedDateTemplate: templateContext.templateOfDay(by: selectedDate, calendar: calendar),
            selectedDate: dateList.selectedDate,
            calendar: calendar,
            storagePolicy: storagePolicy,
            uuidGenerator: { UUID() }
        )
    }

}
