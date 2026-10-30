//
//  HouseworkTemplateDayTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/14.
//

import Foundation
@testable import HometeModel
import Testing

struct HouseworkTemplateDayTest {

    private let inputTemplateItems: [HouseworkTemplateItem] = [
        .init(
            id: .init(id: "id1"),
            title: "1",
            point: 10,
            updatedAt: .previewDate(year: 2026, month: 1, day: 1)
        ),
        .init(
            id: .init(id: "id2"),
            title: "2",
            point: 10,
            updatedAt: .previewDate(year: 2026, month: 1, day: 2)
        ),
        .init(
            id: .init(id: "id3"),
            title: "3",
            point: 10,
            updatedAt: .previewDate(year: 2026, month: 1, day: 3)
        ),
        .init(
            id: .init(id: "id4"),
            title: "4",
            point: 10,
            updatedAt: .previewDate(year: 2026, month: 1, day: 4)
        ),
        .init(
            id: .init(id: "id5"),
            title: "5",
            point: 10,
            updatedAt: .previewDate(year: 2026, month: 1, day: 5)
        ),
    ]

    @Test("すでに登録されているテンプレート家事と指定日付より古いテンプレートの家事は表示する家事に適用しない")
    func applyTemplate() throws {
        // Arrange
        let template = HouseworkTemplateDay(
            dayOfWeek: .monday,
            items: inputTemplateItems
        )

        let registeredItems: [HouseworkItem] = [
            .makeForTest(id: 3, state: .completed, templateHouseworkItemId: .init(id: "id3")),
            .makeForTest(id: 4, state: .completed, templateHouseworkItemId: .init(id: "id4")),
            .makeForTest(id: 10),
        ]

        let selectedDate = Date.previewDate(year: 2026, month: 1, day: 4)
        let uuid = UUID()

        // Act
        let actual = template.applyTemplate(
            registeredItems: registeredItems,
            selectedDate: selectedDate,
            calendar: .japanese,
            storagePolicy: .free,
            uuidGenerator: { uuid }
        )

        // Assert
        let expectedExpired = try #require(Calendar.japanese.date(byAdding: .year, value: 1, to: selectedDate))
        let expected: [HouseworkItem] = registeredItems + [
            .makeForTest(
                id: uuid.uuidString,
                indexedDate: selectedDate,
                title: "1",
                point: 10,
                state: .incomplete,
                expiredAt: expectedExpired,
                templateHouseworkItemId: .init(id: "id1")
            ),
            .makeForTest(
                id: uuid.uuidString,
                indexedDate: selectedDate,
                title: "2",
                point: 10,
                state: .incomplete,
                expiredAt: expectedExpired,
                templateHouseworkItemId: .init(id: "id2")
            ),
        ]

        #expect(actual == expected)
    }

    @Test("テンプレートから作る家事は、テンプレートの家事のメモを引き継ぐ")
    func applyTemplate_copiesMemo() throws {
        // Arrange
        let memo = HouseworkMemo(text: "スーパーで", checklist: [.init(id: "1", title: "牛乳", isChecked: false)])
        let updatedAt = Date.previewDate(year: 2026, month: 1, day: 1)
        let template = HouseworkTemplateDay(
            dayOfWeek: .monday,
            items: [.init(id: .init(id: "id1"), title: "買い出し", point: 10, updatedAt: updatedAt, memo: memo)]
        )
        let selectedDate = Date.previewDate(year: 2026, month: 1, day: 5)

        // Act
        let actual = template.applyTemplate(
            registeredItems: [],
            selectedDate: selectedDate,
            calendar: .japanese,
            storagePolicy: .free,
            idGenerator: { _ in "generated" }
        )

        // Assert
        let expectedExpired = try #require(Calendar.japanese.date(byAdding: .year, value: 1, to: selectedDate))
        let expected: [HouseworkItem] = [
            .makeForTest(
                id: "generated",
                indexedDate: selectedDate,
                title: "買い出し",
                point: 10,
                expiredAt: expectedExpired,
                templateHouseworkItemId: .init(id: "id1"),
                memo: memo
            ),
        ]
        #expect(actual == expected)
    }

    @Test("別の日へまわした記録は、テンプレートの家事を出さない判定にだけ使い、表示する家事には含めない")
    func applyTemplate_postponedRecord_hidesRecordAndTemplateItem() {
        // Arrange
        let template = HouseworkTemplateDay(
            dayOfWeek: .monday,
            items: [
                .init(
                    id: .init(id: "id1"),
                    title: "お皿洗い",
                    point: 10,
                    updatedAt: .previewDate(year: 2026, month: 1, day: 1)
                ),
            ]
        )
        let selectedDate = Date.previewDate(year: 2026, month: 1, day: 5)
        let postponedRecord = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: selectedDate,
            title: "お皿洗い",
            state: .notTodo,
            templateHouseworkItemId: .init(id: "id1"),
            postponedTo: .init(value: .previewDate(year: 2026, month: 1, day: 6))
        )
        let laundry = HouseworkItem.makeForTest(id: 2, indexedDate: selectedDate, title: "洗濯")
        let registeredItems: [HouseworkItem] = [postponedRecord, laundry]
        let expected: [HouseworkItem] = [laundry]

        // Act
        let actual = template.applyTemplate(
            registeredItems: registeredItems,
            selectedDate: selectedDate,
            calendar: .japanese,
            storagePolicy: .free,
            idGenerator: { _ in "generated" }
        )

        // Assert
        #expect(actual == expected)
    }

}
