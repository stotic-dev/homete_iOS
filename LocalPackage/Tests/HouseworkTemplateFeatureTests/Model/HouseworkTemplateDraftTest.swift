//
//  HouseworkTemplateDraftTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/05/16.
//

// swiftlint:disable file_length

import Foundation
@testable import HometeDomain
@testable import HouseworkTemplateFeature
import Testing

enum HouseworkTemplateDraftTest {

    static func makeItem(
        id: String,
        title: String = "title",
        point: Int = 10,
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> HouseworkTemplateItem {
        HouseworkTemplateItem(
            id: .init(id: id),
            title: title,
            point: point,
            updatedAt: updatedAt
        )
    }

    struct ItemsInDayCase {}
    struct RegisteredDaysCase {}
    struct HasUnsavedChangesCase {}
    struct AddItemCase {}
    struct ReplaceItemCase {}
    struct RemoveItemCase {}
    struct AddDayCase {}
    struct SaveDaysCase {}
    struct MakeCase {}

}

private typealias TestCase = HouseworkTemplateDraftTest

extension HouseworkTemplateDraftTest.ItemsInDayCase {

    @Test("指定曜日のアイテムを返す")
    func returnsItemsInDay() {
        // Arrange
        let item = TestCase.makeItem(id: "1")
        let draft = HouseworkTemplateDraft(days: [.monday: [item]])

        // Act
        let actual = draft.items(in: .monday)

        // Assert
        #expect(actual == [item])
    }

    @Test("登録のない曜日では空配列を返す")
    func returnsEmptyWhenNoItems() {
        // Arrange
        let draft = HouseworkTemplateDraft(days: [:])

        // Act
        let actual = draft.items(in: .friday)

        // Assert
        #expect(actual == [])
    }

}

extension HouseworkTemplateDraftTest.RegisteredDaysCase {

    @Test("アイテムが登録されている曜日を表示順で返す")
    func returnsRegisteredDaysInDisplayOrder() {
        // Arrange
        let item = TestCase.makeItem(id: "1")
        let other = TestCase.makeItem(id: "2")
        let draft = HouseworkTemplateDraft(days: [
            .sunday: [item],
            .tuesday: [item, other],
            .monday: [other],
            .friday: [item],
        ])

        // Act
        let actual = draft.registeredDays(for: .init(id: "1"))

        // Assert
        #expect(actual == [.tuesday, .friday, .sunday])
    }

    @Test("該当アイテムが存在しない場合は空配列を返す")
    func returnsEmptyWhenItemNotFound() {
        // Arrange
        let draft = HouseworkTemplateDraft(days: [
            .monday: [TestCase.makeItem(id: "1")],
        ])

        // Act
        let actual = draft.registeredDays(for: .init(id: "missing"))

        // Assert
        #expect(actual == [])
    }

}

extension HouseworkTemplateDraftTest.HasUnsavedChangesCase {

    @Test("内容が同じならfalseを返す")
    func returnsFalseWhenEqual() {
        // Arrange
        let item = TestCase.makeItem(id: "1")
        let draft = HouseworkTemplateDraft(days: [.monday: [item]])
        let initial = HouseworkTemplateDraft(days: [.monday: [item]])

        // Act
        let actual = draft.hasUnsavedChanges(comparedTo: initial)

        // Assert
        #expect(actual == false)
    }

    @Test("内容が異なる場合はtrueを返す")
    func returnsTrueWhenDifferent() {
        // Arrange
        let item = TestCase.makeItem(id: "1")
        let draft = HouseworkTemplateDraft(days: [.monday: [item]])
        let initial = HouseworkTemplateDraft(days: [:])

        // Act
        let actual = draft.hasUnsavedChanges(comparedTo: initial)

        // Assert
        #expect(actual == true)
    }

}

extension HouseworkTemplateDraftTest.AddItemCase {

    @Test("指定された複数曜日にアイテムを追加する")
    func addsItemToTargetDays() {
        // Arrange
        var draft = HouseworkTemplateDraft(days: [:])
        let item = TestCase.makeItem(id: "1")
        let expected = HouseworkTemplateDraft(days: [
            .monday: [item],
            .wednesday: [item],
        ])

        // Act
        draft.addItem(item, to: [.monday, .wednesday])

        // Assert
        #expect(draft == expected)
    }

    @Test("既存のアイテムがある曜日に追加すると末尾に並ぶ")
    func appendsToExistingDay() {
        // Arrange
        let existing = TestCase.makeItem(id: "1")
        let new = TestCase.makeItem(id: "2")
        var draft = HouseworkTemplateDraft(days: [.monday: [existing]])
        let expected = HouseworkTemplateDraft(days: [.monday: [existing, new]])

        // Act
        draft.addItem(new, to: [.monday])

        // Assert
        #expect(draft == expected)
    }

}

extension HouseworkTemplateDraftTest.ReplaceItemCase {

    @Test("全曜日から削除して指定曜日に再登録する")
    func replacesItemAcrossDays() {
        // Arrange
        let oldItem = TestCase.makeItem(id: "1", title: "old")
        let other = TestCase.makeItem(id: "2")
        var draft = HouseworkTemplateDraft(days: [
            .monday: [oldItem, other],
            .tuesday: [oldItem],
        ])
        let newItem = TestCase.makeItem(id: "1", title: "new")
        let expected = HouseworkTemplateDraft(days: [
            .monday: [other],
            .tuesday: [],
            .wednesday: [newItem],
            .friday: [newItem],
        ])

        // Act
        draft.replaceItem(newItem, in: [.wednesday, .friday])

        // Assert
        #expect(draft == expected)
    }

}

extension HouseworkTemplateDraftTest.RemoveItemCase {

    @Test("特定曜日のアイテムだけを削除する")
    func removesFromSpecificDay() {
        // Arrange
        let item = TestCase.makeItem(id: "1")
        var draft = HouseworkTemplateDraft(days: [
            .monday: [item],
            .tuesday: [item],
        ])
        let expected = HouseworkTemplateDraft(days: [
            .monday: [],
            .tuesday: [item],
        ])

        // Act
        draft.removeItem(.init(id: "1"), from: .monday)

        // Assert
        #expect(draft == expected)
    }

    @Test("day指定がnilなら全曜日から削除する")
    func removesFromAllDays() {
        // Arrange
        let item = TestCase.makeItem(id: "1")
        let other = TestCase.makeItem(id: "2")
        var draft = HouseworkTemplateDraft(days: [
            .monday: [item, other],
            .tuesday: [item],
        ])
        let expected = HouseworkTemplateDraft(days: [
            .monday: [other],
            .tuesday: [],
        ])

        // Act
        draft.removeItem(.init(id: "1"), from: nil)

        // Assert
        #expect(draft == expected)
    }

}

extension HouseworkTemplateDraftTest.AddDayCase {

    @Test("追加先の新エントリはupdatedAtがnowで、既存曜日のアイテムは維持される")
    func addsDestinationDayKeepingSourceDays() {
        // Arrange
        let baseDate = Date(timeIntervalSince1970: 0)
        let now = Date(timeIntervalSince1970: 1000)
        let item = TestCase.makeItem(id: "1", title: "task", point: 5, updatedAt: baseDate)
        var draft = HouseworkTemplateDraft(days: [.monday: [item]])
        let addedItem = HouseworkTemplateItem(
            id: .init(id: "1"),
            title: "task",
            point: 5,
            updatedAt: now
        )
        let expected = HouseworkTemplateDraft(days: [
            .monday: [item],
            .wednesday: [addedItem],
        ])

        // Act
        draft.addDay(to: .init(id: "1"), destination: .wednesday, now: now)

        // Assert
        #expect(draft == expected)
    }

    @Test("複数曜日に登録済みのアイテムを別曜日へ追加しても既存曜日は維持される")
    func addsDestinationWhenItemBelongsToMultipleDays() {
        // Arrange
        let baseDate = Date(timeIntervalSince1970: 0)
        let now = Date(timeIntervalSince1970: 1000)
        let item = TestCase.makeItem(id: "1", title: "task", point: 5, updatedAt: baseDate)
        var draft = HouseworkTemplateDraft(days: [
            .monday: [item],
            .tuesday: [item],
        ])
        let addedItem = HouseworkTemplateItem(
            id: .init(id: "1"),
            title: "task",
            point: 5,
            updatedAt: now
        )
        let expected = HouseworkTemplateDraft(days: [
            .monday: [item],
            .tuesday: [item],
            .wednesday: [addedItem],
        ])

        // Act
        draft.addDay(to: .init(id: "1"), destination: .wednesday, now: now)

        // Assert
        #expect(draft == expected)
    }

    @Test("ドロップ先に既に同じアイテムが登録されている場合は何もしない")
    func doesNothingWhenItemAlreadyInDestination() {
        // Arrange
        let baseDate = Date(timeIntervalSince1970: 0)
        let now = Date(timeIntervalSince1970: 1000)
        let item = TestCase.makeItem(id: "1", updatedAt: baseDate)
        var draft = HouseworkTemplateDraft(days: [.monday: [item]])
        let expected = HouseworkTemplateDraft(days: [.monday: [item]])

        // Act
        draft.addDay(to: .init(id: "1"), destination: .monday, now: now)

        // Assert
        #expect(draft == expected)
    }

    @Test("該当アイテムが存在しない場合は何もしない")
    func doesNothingWhenItemNotFound() {
        // Arrange
        let item = TestCase.makeItem(id: "1")
        var draft = HouseworkTemplateDraft(days: [.monday: [item]])
        let expected = HouseworkTemplateDraft(days: [.monday: [item]])

        // Act
        draft.addDay(
            to: .init(id: "missing"),
            destination: .friday,
            now: Date(timeIntervalSince1970: 1000)
        )

        // Assert
        #expect(draft == expected)
    }

}

extension HouseworkTemplateDraftTest.SaveDaysCase {

    @Test("単一曜日のアイテムから、DayOfWeekのrawValueをdayOfWeekに持つ配列を返す")
    func returnsSingleDay() {
        // Arrange
        let item = TestCase.makeItem(id: "1")
        let draft = HouseworkTemplateDraft(days: [.monday: [item]])
        let expected: [HouseworkTemplateDay] = [
            .init(dayOfWeek: DayOfWeek.monday.rawValue, items: [item]),
        ]

        // Act
        let actual = draft.saveDays

        // Assert
        #expect(actual == expected)
    }

    @Test("複数曜日のアイテムから、それぞれをHouseworkTemplateDayに変換した配列を返す")
    func returnsMultipleDays() {
        // Arrange
        let mondayItem = TestCase.makeItem(id: "1")
        let fridayItem = TestCase.makeItem(id: "2")
        let draft = HouseworkTemplateDraft(days: [
            .monday: [mondayItem],
            .friday: [fridayItem],
        ])
        let expected: Set<HouseworkTemplateDay> = [
            .init(dayOfWeek: DayOfWeek.monday.rawValue, items: [mondayItem]),
            .init(dayOfWeek: DayOfWeek.friday.rawValue, items: [fridayItem]),
        ]

        // Act
        let actual = Set(draft.saveDays)

        // Assert
        #expect(actual == expected)
    }

    @Test("空のdraftでは空配列を返す")
    func returnsEmptyWhenNoDays() {
        // Arrange
        let draft = HouseworkTemplateDraft(days: [:])

        // Act
        let actual = draft.saveDays

        // Assert
        #expect(actual == [])
    }

}

extension HouseworkTemplateDraftTest.MakeCase {

    @Test("HouseworkTemplateDayの配列から、曜日をキーとしたDraftを生成する")
    func createsDraftFromTemplates() {
        // Arrange
        let mondayItem = TestCase.makeItem(id: "1")
        let fridayItem = TestCase.makeItem(id: "2")
        let template: [HouseworkTemplateDay] = [
            .init(dayOfWeek: DayOfWeek.monday.rawValue, items: [mondayItem]),
            .init(dayOfWeek: DayOfWeek.friday.rawValue, items: [fridayItem]),
        ]
        let expected = HouseworkTemplateDraft(days: [
            .monday: [mondayItem],
            .friday: [fridayItem],
        ])

        // Act
        let actual = HouseworkTemplateDraft.make(template)

        // Assert
        #expect(actual == expected)
    }

    @Test("DayOfWeekに変換できないdayOfWeekは無視される")
    func ignoresInvalidDayOfWeek() {
        // Arrange
        let validItem = TestCase.makeItem(id: "1")
        let invalidItem = TestCase.makeItem(id: "2")
        let template: [HouseworkTemplateDay] = [
            .init(dayOfWeek: DayOfWeek.monday.rawValue, items: [validItem]),
            .init(dayOfWeek: 99, items: [invalidItem]),
        ]
        let expected = HouseworkTemplateDraft(days: [
            .monday: [validItem],
        ])

        // Act
        let actual = HouseworkTemplateDraft.make(template)

        // Assert
        #expect(actual == expected)
    }

    @Test("空の配列から空のDraftを生成する")
    func createsEmptyDraftFromEmptyTemplate() {
        // Arrange
        let template: [HouseworkTemplateDay] = []
        let expected = HouseworkTemplateDraft(days: [:])

        // Act
        let actual = HouseworkTemplateDraft.make(template)

        // Assert
        #expect(actual == expected)
    }

}
