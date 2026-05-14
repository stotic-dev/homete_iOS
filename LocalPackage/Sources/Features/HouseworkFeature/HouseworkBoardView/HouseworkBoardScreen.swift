//
//  HouseworkBoardScreen.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/09.
//

import HometeDomain
import SwiftUI

public struct HouseworkBoardScreen: View {

    @Environment(\.calendar) var calendar

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
                dateList: $dateList
            )
            .environment(houseworkListStore)
            .environment(houseworkTemplateListStore)
            .onAppear {
                withAnimation {
                    onAppeare(with: houseworkListStore)
                }
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
        houseworkBoardList = .init(
            dailyList: store.items.value,
            selectedDateTemplate: .init(dayOfWeek: 1, items: []), // TODO: Storeから現在の日付のテンプレートを取得
            selectedDate: dateList.selectedDate,
            calendar: calendar,
            uuidGenerator: { UUID() }
        )
    }

}
