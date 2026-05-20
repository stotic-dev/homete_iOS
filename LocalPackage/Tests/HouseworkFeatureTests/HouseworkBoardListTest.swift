//
//  HouseworkBoardListTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/10/02.
//

import Foundation
import HometeDomain
@testable import HouseworkFeature
import Testing

struct HouseworkBoardListTest {

    private static let calendar = Calendar.autoupdatingCurrent

    @Test(
        "選択している日付のみを家事ボードに表示する",
        arguments: [
            Date.now,
            Date.distantFuture,
            Date.distantPast,
        ]
    )
    func initialize(selectTime: Date) {
        // Arrange
        let inputSelectedDateItemList: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: selectTime),
            .makeForTest(id: 2, indexedDate: selectTime),
        ]
        let inputUnselectedDateItemList: [HouseworkItem] = [
            .makeForTest(
                id: 1,
                indexedDate: Self.calendar.date(bySetting: .day, value: -3, of: .now) ?? .now
            ),
        ]
        let inputList: [DailyHouseworkList] = [
            .makeForTest(items: inputSelectedDateItemList),
            .makeForTest(items: inputUnselectedDateItemList),
        ]

        // Act
        let actual = HouseworkBoardList(
            dailyList: inputList,
            selectedDateTemplate: nil,
            selectedDate: selectTime,
            calendar: .japanese,
            uuidGenerator: { UUID() }
        )

        // Assert
        let expected = HouseworkBoardList(
            items: inputSelectedDateItemList.map { .init(
                originalItem: $0,
                isRegistered: true
            ) }
        )
        #expect(actual == expected)
    }

    @Test(
        "指定した状態にマッチする家事を取得する",
        arguments: HouseworkState.allCases
    )
    func items_match_state(expectedState: HouseworkState) {
        // Arrange
        let targetDate = Date.previewDate(year: 2026, month: 1, day: 1)
        let inputHouseworkItem = makeHouseworkItemListWithAllState(targetDate)
        let houseworkBoardList = HouseworkBoardList(
            dailyList: [.makeForTest(items: inputHouseworkItem)],
            selectedDateTemplate: nil,
            selectedDate: targetDate,
            calendar: .japanese,
            uuidGenerator: { UUID() }
        )

        // Act
        let actual = houseworkBoardList.items(matching: expectedState)

        // Assert
        let expected: [HouseworkBoardItem] = inputHouseworkItem.filter { $0.state == expectedState }
            .map {
                .init(originalItem: $0, isRegistered: true)
            }
        #expect(actual == expected)
    }

}

private extension HouseworkBoardListTest {

    func makeHouseworkItemListWithAllState(_ date: Date) -> [HouseworkItem] {
        HouseworkState.allCases.enumerated().flatMap { index, state in
            (1 ... 3).map {
                HouseworkItem.makeForTest(
                    id: index + 1 + $0,
                    indexedDate: date,
                    state: state
                )
            }
        }
    }

}
