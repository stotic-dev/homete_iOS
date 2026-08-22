//
//  HouseworkBoardList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation
import HometeDomain

struct HouseworkBoardList: Equatable {

    private(set) var items: [HouseworkBoardItem]

    func items(matching state: HouseworkState) -> [HouseworkBoardItem] {
        items.filter { $0.state == state }
    }

}

extension HouseworkBoardList {

    init(
        dailyList: [DailyHouseworkList],
        selectedDateTemplate: HouseworkTemplateDay?,
        selectedDate: Date,
        calendar: Calendar,
        storagePolicy: HouseworkStoragePolicy,
        uuidGenerator: () -> UUID
    ) {
        let items = dailyList
            .first {
                $0.metaData.indexedDate == .init(value: selectedDate)
            }?.items ?? []

        // テンプレートが存在するときは、条件に合ったテンプレートの家事を未完了で追加する
        guard let selectedDateTemplate else {
            self.items = items.map { .init(originalItem: $0, isRegistered: true) }
            return
        }

        self.items = selectedDateTemplate.applyTemplate(
            registeredItems: items,
            selectedDate: selectedDate,
            calendar: calendar,
            storagePolicy: storagePolicy,
            uuidGenerator: uuidGenerator
        )
        .map { .init(originalItem: $0, isRegistered: false) }
    }

}
