//
//  StoredAllHouseworkListTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/11/22.
//

import Foundation
import Testing
@testable import homete

struct StoredAllHouseworkListTest {
    
    private static let inputFirstDate = Date.dateComponents(year: 2025, month: 1, day: 1)
    private static let inputSecondDate = Date.dateComponents(year: 2025, month: 1, day: 2)

    @Test("家事リストは家事の日付毎に保持される")
    func makeMultiDateList() {
        
        let inputFirstHouseworkGroup  = makeAllCasesItems(
            at: Self.inputFirstDate,
            offset: 0
        )
        let inputSecondHouseworkGroup  = makeAllCasesItems(
            at: Self.inputSecondDate,
            offset: inputFirstHouseworkGroup.count
        )
        let inputHouseworkItem = inputFirstHouseworkGroup + inputSecondHouseworkGroup
        
        let actual = StoredAllHouseworkList.makeMultiDateList(
            items: inputHouseworkItem,
            calendar: .current
        )
        
        let sortedActualValue = actual.value.sorted { $0.metaData.indexedDate.value < $1.metaData.indexedDate.value }
        let sortedActual = StoredAllHouseworkList(value: sortedActualValue)
        let expected = StoredAllHouseworkList(value: [
            .makeForTest(items: inputFirstHouseworkGroup),
            .makeForTest(items: inputSecondHouseworkGroup)
        ])
        #expect(sortedActual == expected)
    }
    
    @Test(
        "保持している家事リストからidと対象日に合致する単一の家事を取得する",
        arguments: [
            HouseworkItem.makeForTest(id: 999, indexedDate: Self.inputFirstDate),
            .makeForTest(id: 999, indexedDate: Date.now)
        ]
    )
    func items(expectedItem: HouseworkItem) {
        
        let inputFirstHouseworkGroup  = makeAllCasesItems(
            at: Self.inputFirstDate,
            offset: 0
        )
        let list = StoredAllHouseworkList.makeMultiDateList(
            items: (inputFirstHouseworkGroup + [expectedItem]).shuffled(),
            calendar: .current
        )
        
        let actual = list.item(expectedItem.id, expectedItem.indexedDate)
        
        #expect(actual == expectedItem)
    }
}

private extension StoredAllHouseworkListTest {
    
    func makeAllCasesItems(at indexedDate: Date, offset: Int) -> [HouseworkItem] {
        return [
            .makeForTest(id: offset + 1, indexedDate: indexedDate),
            .makeForTest(id: offset + 2, indexedDate: indexedDate, state: .pendingApproval),
            .makeForTest(id: offset + 3, indexedDate: indexedDate, state: .completed),
            .makeForTest(id: offset + 4, indexedDate: indexedDate, executorId: "dummy", executedAt: .now)
        ]
    }
}
