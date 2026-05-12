//
//  HouseworkBoardScreen.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/09.
//

import SwiftUI

public struct HouseworkBoardScreen: View {

    @State var houseworkListStore: HouseworkListStore?
    @State var houseworkBoardList: HouseworkBoardList = .init(items: [])
    @State var dateList = HouseworkDateList()

    public static func make(houseworkListStore: HouseworkListStore?) -> some View {
        HouseworkBoardScreen(houseworkListStore: houseworkListStore)
    }

    public var body: some View {
        if let houseworkListStore {
            HouseworkBoardView(
                houseworkBoardList: $houseworkBoardList,
                dateList: $dateList
            )
            .environment(houseworkListStore)
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
            selectedDate: dateList.selectedDate
        )
    }

}
