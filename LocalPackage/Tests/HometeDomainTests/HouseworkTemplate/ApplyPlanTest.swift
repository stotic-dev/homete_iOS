//
//  ApplyPlanTest.swift
//  HometeDomainTests
//
//  Created by Taichi Sato on 2026/05/14.
//

import Foundation
@testable import HometeDomain
import Testing

struct ApplyPlanTest {

    private let inputCohabitantId = "cohabitantId"
    private let inputCalendar = Calendar.japanese
    /// 2026-05-09 は土曜日（dayOfWeek=6）
    private let inputNow = Date.previewDate(year: 2026, month: 5, day: 9)
    /// 2026-05-09 から 2026-05-15 までの7日分
    private let expectedTargetDates = [
        Date.previewDate(year: 2026, month: 5, day: 9),
        Date.previewDate(year: 2026, month: 5, day: 10),
        Date.previewDate(year: 2026, month: 5, day: 11),
        Date.previewDate(year: 2026, month: 5, day: 12),
        Date.previewDate(year: 2026, month: 5, day: 13),
        Date.previewDate(year: 2026, month: 5, day: 14),
        Date.previewDate(year: 2026, month: 5, day: 15),
    ]

    @Test("適用範囲外（now-1日や+7日以降）のincomplete家事は除外される")
    func make_filtersOutOfRangeItems() {
        // Arrange

        let beforeRangeItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 8)
        )
        let afterRangeItem = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 16)
        )
        let expected = ApplyPlan(
            days: [],
            cohabitantId: inputCohabitantId,
            targetDates: expectedTargetDates,
            targetIncompleteItems: [],
            calendar: inputCalendar
        )

        // Act

        let actual = ApplyPlan.make(
            days: [],
            cohabitantId: inputCohabitantId,
            incompleteItems: [beforeRangeItem, afterRangeItem],
            now: inputNow,
            calendar: inputCalendar
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("適用範囲内（now〜+6日）のincomplete家事はtargetIncompleteItemsに含まれる")
    func make_includesInRangeItems() {
        // Arrange

        let inRangeItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 10)
        )
        let expected = ApplyPlan(
            days: [],
            cohabitantId: inputCohabitantId,
            targetDates: expectedTargetDates,
            targetIncompleteItems: [inRangeItem],
            calendar: inputCalendar
        )

        // Act

        let actual = ApplyPlan.make(
            days: [],
            cohabitantId: inputCohabitantId,
            incompleteItems: [inRangeItem],
            now: inputNow,
            calendar: inputCalendar
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("適用範囲内に未完了の家事がある場合、上書き確認が必要となる")
    func requiresOverwriteConfirmation_returnsTrueWhenIncompleteItemsExist() {
        // Arrange

        let inRangeItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 10)
        )
        let plan = ApplyPlan.make(
            days: [],
            cohabitantId: inputCohabitantId,
            incompleteItems: [inRangeItem],
            now: inputNow,
            calendar: inputCalendar
        )

        // Act

        let actual = plan.requiresOverwriteConfirmation

        // Assert

        #expect(actual == true)
    }

    @Test("適用範囲内に未完了の家事がない場合、上書き確認は不要となる")
    func requiresOverwriteConfirmation_returnsFalseWhenNoIncompleteItems() {
        // Arrange

        let plan = ApplyPlan.make(
            days: [],
            cohabitantId: inputCohabitantId,
            incompleteItems: [],
            now: inputNow,
            calendar: inputCalendar
        )

        // Act

        let actual = plan.requiresOverwriteConfirmation

        // Assert

        #expect(actual == false)
    }

    @Test("makeNewItemsは該当曜日のテンプレートアイテムを家事として生成する")
    func makeNewItems_generatesItemsForMatchingWeekday() {
        // Arrange

        let fixedItemId = "generatedId"
        let inputDays: [HouseworkTemplateDay] = [
            .init(dayOfWeek: 6, items: [.init(title: "週末掃除", point: 30)]),
        ]
        let plan = ApplyPlan.make(
            days: inputDays,
            cohabitantId: inputCohabitantId,
            incompleteItems: [],
            now: inputNow,
            calendar: inputCalendar
        )
        let expected = [
            HouseworkItem(
                id: fixedItemId,
                indexedDate: HouseworkIndexedDate(value: Date.previewDate(year: 2026, month: 5, day: 9)),
                title: "週末掃除",
                point: 30,
                state: .incomplete,
                executorId: nil,
                executedAt: nil,
                reviewerId: nil,
                approvedAt: nil,
                reviewerComment: nil,
                expiredAt: Date.previewDate(year: 2027, month: 5, day: 9)
            ),
        ]

        // Act

        let actual = plan.makeNewItems(idGenerator: { fixedItemId })

        // Assert

        #expect(actual == expected)
    }

    @Test("makeNewItemsは適用範囲内に該当曜日が無い場合、空配列を返す")
    func makeNewItems_returnsEmptyWhenNoMatchingWeekdayInRange() {
        // Arrange

        // 適用範囲（5/9土〜5/15金）に存在しない dayOfWeek=99 を指定
        let plan = ApplyPlan.make(
            days: [.init(dayOfWeek: 99, items: [.init(title: "存在しない", point: 30)])],
            cohabitantId: inputCohabitantId,
            incompleteItems: [],
            now: inputNow,
            calendar: inputCalendar
        )

        // Act

        let actual = plan.makeNewItems(idGenerator: { "generatedId" })

        // Assert

        #expect(actual == [])
    }

}
