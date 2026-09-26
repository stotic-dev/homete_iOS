//
//  HouseworkTemplateDraftMonthlyItemTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/09/26.
//

import Foundation
@testable import HometeDomain
@testable import HouseworkTemplateFeature
import Testing

struct HouseworkTemplateDraftMonthlyItemTest {

    private static func makeItem(id: String, title: String = "title") -> HouseworkTemplateItem {
        HouseworkTemplateItem(
            id: .init(id: id),
            title: title,
            point: 10,
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    @Test("毎月の繰り返しで追加すると、毎月の家事の末尾に追加する")
    func addItemMonthly() {
        // Arrange
        let existing = HouseworkTemplateMonthlyItem(item: Self.makeItem(id: "1"), rule: .dayOfMonth(1))
        let newItem = Self.makeItem(id: "2")
        var draft = HouseworkTemplateDraft(monthlyItems: [existing])
        let expected = HouseworkTemplateDraft(monthlyItems: [
            existing,
            .init(item: newItem, rule: .dayOfMonth(25)),
        ])

        // Act
        draft.addItem(newItem, recurrence: .monthly(.dayOfMonth(25)))

        // Assert
        #expect(draft == expected)
    }

    @Test("毎週の家事を毎月に変えて置き換えると、全曜日から消して毎月の家事に追加する")
    func replaceWeeklyItemWithMonthly() {
        // Arrange
        let item = Self.makeItem(id: "1")
        var draft = HouseworkTemplateDraft(days: [.monday: [item], .friday: [item]])
        let newItem = Self.makeItem(id: "1", title: "new")
        let expected = HouseworkTemplateDraft(
            days: [.monday: [], .friday: []],
            monthlyItems: [.init(item: newItem, rule: .dayOfMonth(31))]
        )

        // Act
        draft.replaceItem(newItem, recurrence: .monthly(.dayOfMonth(31)))

        // Assert
        #expect(draft == expected)
    }

    @Test("毎月の家事を毎週に変えて置き換えると、毎月の家事から消して指定曜日に追加する")
    func replaceMonthlyItemWithWeekly() {
        // Arrange
        let item = Self.makeItem(id: "1")
        var draft = HouseworkTemplateDraft(monthlyItems: [.init(item: item, rule: .dayOfMonth(1))])
        let expected = HouseworkTemplateDraft(days: [.tuesday: [item]], monthlyItems: [])

        // Act
        draft.replaceItem(item, recurrence: .weekly([.tuesday]))

        // Assert
        #expect(draft == expected)
    }

    @Test("曜日を指定せずに削除すると、毎月の家事からも削除する")
    func removeItemFromMonthlyItems() {
        // Arrange
        let target = HouseworkTemplateMonthlyItem(item: Self.makeItem(id: "1"), rule: .dayOfMonth(1))
        let other = HouseworkTemplateMonthlyItem(item: Self.makeItem(id: "2"), rule: .dayOfMonth(2))
        var draft = HouseworkTemplateDraft(monthlyItems: [target, other])
        let expected = HouseworkTemplateDraft(monthlyItems: [other])

        // Act
        draft.removeItem(target.id, from: nil)

        // Assert
        #expect(draft == expected)
    }

    @Test(
        "アイテムの繰り返し方を、登録先（毎週の曜日または毎月のルール）から返す",
        arguments: [
            (id: "weekly", expected: Optional(HouseworkRecurrence.weekly([.monday, .friday]))),
            (id: "monthly", expected: .monthly(.dayOfMonth(25))),
            (id: "unknown", expected: nil),
        ]
    )
    func recurrence(id: String, expected: HouseworkRecurrence?) {
        // Arrange
        let weeklyItem = Self.makeItem(id: "weekly")
        let draft = HouseworkTemplateDraft(
            days: [.monday: [weeklyItem], .friday: [weeklyItem]],
            monthlyItems: [.init(item: Self.makeItem(id: "monthly"), rule: .dayOfMonth(25))]
        )

        // Act
        let actual = draft.recurrence(for: .init(id: id))

        // Assert
        #expect(actual == expected)
    }

    @Test("毎月の家事を日付順に並べ、同じ日付の家事はID順に並べて返す")
    func displayedMonthlyItems() {
        // Arrange
        let day25B = HouseworkTemplateMonthlyItem(item: Self.makeItem(id: "b"), rule: .dayOfMonth(25))
        let day3 = HouseworkTemplateMonthlyItem(item: Self.makeItem(id: "c"), rule: .dayOfMonth(3))
        let day25A = HouseworkTemplateMonthlyItem(item: Self.makeItem(id: "a"), rule: .dayOfMonth(25))
        let draft = HouseworkTemplateDraft(monthlyItems: [day25B, day3, day25A])
        let expected = [day3, day25A, day25B]

        // Act
        let actual = draft.displayedMonthlyItems

        // Assert
        #expect(actual == expected)
    }

    @Test("毎月の家事の並び順だけが違うドラフト同士は、未保存の変更なしとみなす")
    func hasNoUnsavedChangesWhenOnlyMonthlyOrderDiffers() {
        // Arrange
        let rent = HouseworkTemplateMonthlyItem(item: Self.makeItem(id: "b"), rule: .dayOfMonth(25))
        let cleaning = HouseworkTemplateMonthlyItem(item: Self.makeItem(id: "a"), rule: .dayOfMonth(25))
        let draft = HouseworkTemplateDraft(monthlyItems: [rent, cleaning])
        let initial = HouseworkTemplateDraft(monthlyItems: [cleaning, rent])

        // Act
        let actual = draft.hasUnsavedChanges(comparedTo: initial)

        // Assert
        #expect(actual == false)
    }

}
