//
//  HouseworkTemplateContextTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/14.
//

import Foundation
@testable import HometeDomain
import Testing

enum HouseworkTemplateContextTest {

    struct TemplateOfDayCase {}
    struct HasTemplateCase {}

}

extension HouseworkTemplateContextTest.TemplateOfDayCase {

    @Test(
        "指定した日付に対応した曜日のテンプレートを返す",
        arguments: (1 ... 7).map {
            Date.previewDate(year: 2026, month: 1, day: $0)
        }
    )
    func templateOfDay(inputDate: Date) throws {
        // Arrange
        let calendar = Calendar.japanese
        let context = HouseworkTemplateContext(metadata: nil, houseworkTemplate: [
            .init(dayOfWeek: .sunday, items: [
                .init(id: .init(id: "1"), title: "1", point: 1, updatedAt: .now),
            ]),
            .init(dayOfWeek: .monday, items: [
                .init(id: .init(id: "2"), title: "2", point: 2, updatedAt: .now),
            ]),
            .init(dayOfWeek: .tuesday, items: [
                .init(id: .init(id: "3"), title: "3", point: 3, updatedAt: .now),
            ]),
            .init(dayOfWeek: .wednesday, items: [
                .init(id: .init(id: "4"), title: "4", point: 4, updatedAt: .now),
            ]),
            .init(dayOfWeek: .thursday, items: [
                .init(id: .init(id: "5"), title: "5", point: 5, updatedAt: .now),
            ]),
            .init(dayOfWeek: .friday, items: [
                .init(id: .init(id: "6"), title: "6", point: 6, updatedAt: .now),
            ]),
            .init(dayOfWeek: .saturday, items: [
                .init(id: .init(id: "7"), title: "7", point: 7, updatedAt: .now),
            ]),
        ])

        // Act
        let actual = context.templateOfDay(by: inputDate, calendar: calendar)

        // Assert
        let dayOfWeek = try #require(DayOfWeek.of(date: inputDate, calendar: calendar))
        let expected = try #require(context.houseworkTemplate.first { $0.dayOfWeek == dayOfWeek })
        #expect(actual == expected)
    }

}

extension HouseworkTemplateContextTest.HasTemplateCase {

    @Test("metadataがnilの場合はfalseを返す")
    func returnsFalseWhenMetadataIsNil() {
        // Arrange
        let context = HouseworkTemplateContext(metadata: nil, houseworkTemplate: [])

        // Act
        let actual = context.hasTemplate

        // Assert
        #expect(actual == false)
    }

    @Test("metadataが指定されている場合はtrueを返す（houseworkTemplateが空でも）")
    func returnsTrueWhenMetadataExists() {
        // Arrange
        let context = HouseworkTemplateContext(
            metadata: .init(templateId: "templateId", name: "テンプレ"),
            houseworkTemplate: []
        )

        // Act
        let actual = context.hasTemplate

        // Assert
        #expect(actual == true)
    }

}
