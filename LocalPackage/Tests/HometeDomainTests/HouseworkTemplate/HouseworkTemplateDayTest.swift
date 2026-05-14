//
//  HouseworkTemplateDayTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/14.
//

import Foundation
@testable import HometeDomain
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
            dayOfWeek: 1,
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

}
