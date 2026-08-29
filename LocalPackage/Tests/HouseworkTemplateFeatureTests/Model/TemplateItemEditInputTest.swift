//
//  TemplateItemEditInputTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/05/20.
//

import Foundation
@testable import HometeDomain
@testable import HouseworkTemplateFeature
import Testing

enum TemplateItemEditInputTest {

    static let itemId = HouseworkTemplateItem.ItemId(id: "1")

    static func makeInput(
        title: String = "ゴミ出し",
        point: Int? = 10,
        days: Set<DayOfWeek> = [.monday]
    ) -> TemplateItemEditInput {
        TemplateItemEditInput(
            itemId: itemId,
            title: title,
            point: point,
            days: days
        )
    }

    struct CanConfirmCreateModeCase {}
    struct CanConfirmEditModeCase {}

}

private typealias TestCase = TemplateItemEditInputTest

extension TemplateItemEditInputTest.CanConfirmCreateModeCase {

    @Test("新規作成モードで全項目入力済みのときtrueを返す")
    func returnsTrueWhenAllFieldsFilled() {
        // Arrange
        let input = TestCase.makeInput()

        // Act
        let actual = input.canConfirm(.create)

        // Assert
        #expect(actual == true)
    }

    @Test("新規作成モードでtitleが空（または空白のみ）のときfalseを返す")
    func returnsFalseWhenTitleIsBlank() {
        // Arrange
        let input = TestCase.makeInput(title: "   ")

        // Act
        let actual = input.canConfirm(.create)

        // Assert
        #expect(actual == false)
    }

    @Test("新規作成モードでdaysが空のときfalseを返す")
    func returnsFalseWhenDaysAreEmpty() {
        // Arrange
        let input = TestCase.makeInput(days: [])

        // Act
        let actual = input.canConfirm(.create)

        // Assert
        #expect(actual == false)
    }

    @Test("新規作成モードでpointが未選択のときfalseを返す")
    func returnsFalseWhenPointIsNil() {
        // Arrange
        let input = TestCase.makeInput(point: nil)

        // Act
        let actual = input.canConfirm(.create)

        // Assert
        #expect(actual == false)
    }

}

extension TemplateItemEditInputTest.CanConfirmEditModeCase {

    @Test("編集モードで全項目入力済み、かつ既存内容から変更がある場合にtrueを返す")
    func returnsTrueWhenChangedFromBefore() {
        // Arrange
        let before = TestCase.makeInput(title: "ゴミ出し", point: 10)
        let edited = TestCase.makeInput(title: "ゴミ出し（更新）", point: 10)

        // Act
        let actual = edited.canConfirm(.edit(before: before))

        // Assert
        #expect(actual == true)
    }

    @Test("編集モードで既存内容と変更がない場合はfalseを返す")
    func returnsFalseWhenNoChangeFromBefore() {
        // Arrange
        let before = TestCase.makeInput()
        let edited = TestCase.makeInput()

        // Act
        let actual = edited.canConfirm(.edit(before: before))

        // Assert
        #expect(actual == false)
    }

    @Test("編集モードでtitleが空（または空白のみ）のときfalseを返す")
    func returnsFalseWhenTitleIsBlank() {
        // Arrange
        let before = TestCase.makeInput(title: "ゴミ出し")
        let edited = TestCase.makeInput(title: "   ")

        // Act
        let actual = edited.canConfirm(.edit(before: before))

        // Assert
        #expect(actual == false)
    }

    @Test("編集モードでdaysが空のときfalseを返す")
    func returnsFalseWhenDaysAreEmpty() {
        // Arrange
        let before = TestCase.makeInput()
        let edited = TestCase.makeInput(days: [])

        // Act
        let actual = edited.canConfirm(.edit(before: before))

        // Assert
        #expect(actual == false)
    }

    @Test("編集モードでpointが未選択のときfalseを返す")
    func returnsFalseWhenPointIsNil() {
        // Arrange
        let before = TestCase.makeInput(point: 10)
        let edited = TestCase.makeInput(point: nil)

        // Act
        let actual = edited.canConfirm(.edit(before: before))

        // Assert
        #expect(actual == false)
    }

}
