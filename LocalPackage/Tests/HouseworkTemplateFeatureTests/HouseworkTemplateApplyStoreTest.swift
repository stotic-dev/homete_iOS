//
//  HouseworkTemplateApplyStoreTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/05/09.
//

import Foundation
import HometeDomain
import Testing

@testable import HouseworkTemplateFeature

@MainActor
struct HouseworkTemplateApplyStoreTest {

    private let inputCohabitantId = "cohabitantId"

    @Test("適用準備: 範囲外（now-1日や+7日以降）のincomplete家事は除外され、上書き確認は不要となる")
    func prepareApply_outOfRange_doesNotRequireConfirmation() {

        // Arrange

        let calendar = Calendar.japanese
        let now = Date.previewDate(year: 2026, month: 5, day: 9)
        let beforeRangeItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 8)
        )
        let afterRangeItem = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 16)
        )
        let store = HouseworkTemplateApplyStore()

        // Act

        store.prepareApply(
            days: [],
            cohabitantId: inputCohabitantId,
            incompleteItems: [beforeRangeItem, afterRangeItem],
            now: now,
            calendar: calendar
        )

        // Assert

        #expect(store.isOverwriteConfirmationRequired == false)
    }

    @Test("適用準備: 範囲内（now〜+6日）のincomplete家事があると、上書き確認が必要となる")
    func prepareApply_inRange_requiresConfirmation() {

        // Arrange

        let calendar = Calendar.japanese
        let now = Date.previewDate(year: 2026, month: 5, day: 9)
        let inRangeItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 10),
        )
        let store = HouseworkTemplateApplyStore()

        // Act

        store.prepareApply(
            days: [],
            cohabitantId: inputCohabitantId,
            incompleteItems: [inRangeItem],
            now: now,
            calendar: calendar
        )

        // Assert

        #expect(store.isOverwriteConfirmationRequired == true)
    }

    @Test("適用実行: 範囲内のincomplete家事をremoveItemで削除する")
    func executeApply_removesIncompleteItemsInRange() async throws {

        // Arrange

        let calendar = Calendar.japanese
        let now = Date.previewDate(year: 2026, month: 5, day: 9)
        let targetItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 10),
        )

        try await confirmation { confirmation in

            let store = HouseworkTemplateApplyStore(
                houseworkClient: .init(
                    removeItemHandler: { item, cohabitantId in

                        // Assert

                        #expect(item == targetItem)
                        #expect(cohabitantId == self.inputCohabitantId)
                        confirmation()
                    }
                )
            )

            // Act

            store.prepareApply(
                days: [],
                cohabitantId: inputCohabitantId,
                incompleteItems: [targetItem],
                now: now,
                calendar: calendar
            )
            try await store.executeApply()
        }
    }

    @Test("適用実行: テンプレートのアイテムを該当曜日に書き込む")
    func executeApply_writesTemplateItemsToMatchingWeekday() async throws {

        // Arrange

        let calendar = Calendar.japanese
        // 2026-05-09 は土曜日（weekday=7, dayOfWeek=6）
        let now = Date.previewDate(year: 2026, month: 5, day: 9)
        let inputDays: [HouseworkTemplateDay] = [
            .init(dayOfWeek: 6, items: [.init(title: "週末掃除", point: 30)])
        ]
        let fixedItemId = "generatedId"
        let expectedIndexedDate = HouseworkIndexedDate(value: now)

        try await confirmation { confirmation in

            let store = HouseworkTemplateApplyStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, cohabitantId in

                        // Assert

                        #expect(item.id == fixedItemId)
                        #expect(item.title == "週末掃除")
                        #expect(item.point == 30)
                        #expect(item.state == .incomplete)
                        #expect(item.indexedDate == expectedIndexedDate)
                        #expect(cohabitantId == self.inputCohabitantId)
                        confirmation()
                    }
                ),
                idGenerator: { fixedItemId }
            )

            // Act

            store.prepareApply(
                days: inputDays,
                cohabitantId: inputCohabitantId,
                incompleteItems: [],
                now: now,
                calendar: calendar
            )
            try await store.executeApply()
        }
    }

    @Test("適用実行後、isOverwriteConfirmationRequiredはfalseに戻る")
    func executeApply_resetsConfirmationFlag() async throws {

        // Arrange

        let calendar = Calendar.japanese
        let now = Date.previewDate(year: 2026, month: 5, day: 9)
        let inRangeItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 10),
        )
        let store = HouseworkTemplateApplyStore()

        // Act

        store.prepareApply(
            days: [],
            cohabitantId: inputCohabitantId,
            incompleteItems: [inRangeItem],
            now: now,
            calendar: calendar
        )
        try await store.executeApply()

        // Assert

        #expect(store.isOverwriteConfirmationRequired == false)
    }

    @Test("キャンセル後にexecuteApplyを呼んでも、Clientは呼ばれない")
    func cancelApply_clearsPendingPlan() async throws {

        // Arrange

        let calendar = Calendar.japanese
        let now = Date.previewDate(year: 2026, month: 5, day: 9)
        let inRangeItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date.previewDate(year: 2026, month: 5, day: 10),
        )
        let store = HouseworkTemplateApplyStore(
            houseworkClient: .init(
                insertOrUpdateItemHandler: { _, _ in

                    Issue.record("insertOrUpdateItemは呼ばれてはいけない")
                },
                removeItemHandler: { _, _ in

                    Issue.record("removeItemは呼ばれてはいけない")
                }
            )
        )

        // Act

        store.prepareApply(
            days: [],
            cohabitantId: inputCohabitantId,
            incompleteItems: [inRangeItem],
            now: now,
            calendar: calendar
        )
        store.cancelApply()
        try await store.executeApply()

        // Assert

        #expect(store.isOverwriteConfirmationRequired == false)
    }
}
