//
//  HouseworkDateListTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import Foundation
import HometeDomain
@testable import HouseworkFeature
import Testing

struct HouseworkDateListTest {

    // anchorDate = 2026/04/15、selectedDate = 2026/04/15（= anchor当日）を基準にテスト
    // 無料プラン: 過去30日/未来7日が選択可能、前後に3日ずつpadding → 33 + 10 + 1 = 44件
    // プレミアムプラン: 過去365日/未来7日が選択可能、前後に3日ずつpadding → 368 + 10 + 1 = 379件
    private static let calendar = Calendar.japanese
    private static let anchorDate = Date.previewDate(year: 2026, month: 4, day: 15)

    // MARK: - items

    @Test("無料プランでは過去33日〜未来10日の合計44件のアイテムリストを保持する")
    func items_count_free() {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        #expect(sut.items.count == 44)
    }

    @Test("プレミアムプランでは過去368日〜未来10日の合計379件のアイテムリストを保持する")
    func items_count_premium() {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .premium)
        #expect(sut.items.count == 379)
    }

    @Test("無料プランのアイテムリストの先頭日付はanchorDate-33から始まる")
    func items_firstDate() {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        let expected = Self.calendar.date(
            byAdding: .day,
            value: -33,
            to: Self.calendar.startOfDay(for: Self.anchorDate)
        )
        #expect(sut.items.first?.date == expected)
    }

    @Test("アイテムリストの末尾日付はanchorDate+10で終わる")
    func items_lastDate() {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        let expected = Self.calendar.date(
            byAdding: .day,
            value: 10,
            to: Self.calendar.startOfDay(for: Self.anchorDate)
        )
        #expect(sut.items.last?.date == expected)
    }

    @Test("アイテムリストの日付は1日刻みで連続している")
    func items_continuous() {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        let dates = sut.items.map(\.date)
        let isConsecutive = zip(dates, dates.dropFirst()).allSatisfy { prev, next in
            Self.calendar.dateComponents([.day], from: prev, to: next).day == 1
        }
        #expect(isConsecutive)
    }

    // MARK: - hasStorageLimit

    @Test("無料プランは保存期間の上限を持つ")
    func hasStorageLimit_free() {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        #expect(sut.hasStorageLimit == true)
    }

    @Test("プレミアムプランは保存期間の上限を持たない")
    func hasStorageLimit_premium() {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .premium)
        #expect(sut.hasStorageLimit == false)
    }

    // MARK: - oldestSelectableDate

    @Test("無料プランで選択できる最古の日付はanchorDate-30になる")
    func oldestSelectableDate_free() {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        let expected = Self.calendar.date(
            byAdding: .day,
            value: -30,
            to: Self.calendar.startOfDay(for: Self.anchorDate)
        )
        #expect(sut.oldestSelectableDate(calendar: Self.calendar) == expected)
    }

    // MARK: - selectedDateのクランプ

    @Test("プレミアムから無料に切り替わった場合、選択中の日付は選択可能な最古の日付に丸められる")
    func selectedDate_clamped_toOldestSelectableDate() throws {
        // Arrange: プレミアムでしか選べない90日前を選択している状態を再現する
        let selectedDate = try #require(
            Self.calendar.date(byAdding: .day, value: -90, to: Self.anchorDate)
        )
        let expected = Self.calendar.date(
            byAdding: .day,
            value: -30,
            to: Self.calendar.startOfDay(for: Self.anchorDate)
        )

        // Act
        let sut = makeSut(selectedDate: selectedDate, storagePolicy: .free)

        // Assert
        #expect(sut.selectedDate == expected)
    }

    @Test("選択可能な範囲より未来の日付は選択可能な最新の日付に丸められる")
    func selectedDate_clamped_toNewestSelectableDate() throws {
        // Arrange
        let selectedDate = try #require(
            Self.calendar.date(byAdding: .day, value: 30, to: Self.anchorDate)
        )
        let expected = Self.calendar.date(
            byAdding: .day,
            value: 7,
            to: Self.calendar.startOfDay(for: Self.anchorDate)
        )

        // Act
        let sut = makeSut(selectedDate: selectedDate, storagePolicy: .free)

        // Assert
        #expect(sut.selectedDate == expected)
    }

    @Test("丸められた選択日はアイテムリスト上でもselectedになる")
    func selectedDate_clamped_itemStateIsSelected() throws {
        // Arrange
        let selectedDate = try #require(
            Self.calendar.date(byAdding: .day, value: -90, to: Self.anchorDate)
        )

        // Act
        let sut = makeSut(selectedDate: selectedDate, storagePolicy: .free)

        // Assert
        let selectedItems = sut.items.filter { $0.state == .selected }
        #expect(selectedItems.map(\.date) == [sut.selectedDate])
    }

    @Test("選択可能な範囲内の日付は丸められない")
    func selectedDate_notClamped_whenSelectable() throws {
        // Arrange
        let selectedDate = try #require(
            Self.calendar.date(byAdding: .day, value: -90, to: Self.anchorDate)
        )
        let expected = Self.calendar.startOfDay(for: selectedDate)

        // Act
        let sut = makeSut(selectedDate: selectedDate, storagePolicy: .premium)

        // Assert
        #expect(sut.selectedDate == expected)
    }

    // MARK: - state: selected

    @Test(
        "selectedDateと同じ日付のアイテム状態はselectedを返す",
        arguments: [
            Date.previewDate(year: 2026, month: 4, day: 15), // anchor当日
            Date.previewDate(year: 2026, month: 4, day: 12), // anchor-3（selectable範囲内）
            Date.previewDate(year: 2026, month: 4, day: 18), // anchor+3（selectable範囲内）
        ]
    )
    func state_returns_selected(selectedDate: Date) {
        let sut = makeSut(selectedDate: selectedDate, storagePolicy: .free)
        let actual = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: selectedDate) }?.state
        #expect(actual == .selected)
    }

    // MARK: - state: selectable

    @Test(
        "無料プランで過去30日〜未来7日の範囲かつselected以外のアイテム状態はselectableを返す",
        arguments: [-30, -20, -8, -7, -1, 1, 3, 7] // 0はanchor=selectedなのでselectedになる
    )
    func state_returns_selectable(offsetFromAnchor: Int) throws {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        let actual = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: targetDate) }?.state
        #expect(actual == .selectable)
    }

    @Test("プレミアムプランでは1年前の日付もselectableを返す")
    func state_returns_selectable_premium() throws {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .premium)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: -365, to: Self.anchorDate))
        let actual = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: targetDate) }?.state
        #expect(actual == .selectable)
    }

    // MARK: - state: unselectable

    @Test(
        "無料プランで過去30日〜未来7日の範囲外のアイテム状態はunselectableを返す",
        arguments: [-33, -32, -31, 8, 9, 10]
    )
    func state_returns_unselectable(offsetFromAnchor: Int) throws {
        let sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        let actual = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: targetDate) }?.state
        #expect(actual == .unselectable)
    }

    // MARK: - selectDate

    @Test(
        "selectableな日付を選択するとselectedDateが更新されその日付のアイテム状態がselectedになる",
        arguments: [-30, -7, -3, -1, 1, 3, 7]
    )
    func selectDate_selectable(offsetFromAnchor: Int) throws {
        var sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        sut.selectDate(targetDate, calendar: Self.calendar)
        let expectedSelectedDate = Self.calendar.startOfDay(for: targetDate)
        #expect(sut.selectedDate == expectedSelectedDate)
        let selectedItem = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: targetDate) }
        #expect(selectedItem?.state == .selected)
    }

    @Test(
        "selectableな日付を選択すると旧selectedDateのアイテム状態がselectableに変わる",
        arguments: [-30, -7, -3, -1, 1, 3, 7]
    )
    func selectDate_previousSelected_becomes_selectable(offsetFromAnchor: Int) throws {
        var sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        sut.selectDate(targetDate, calendar: Self.calendar)
        let prevSelectedItem = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: Self.anchorDate) }
        #expect(prevSelectedItem?.state == .selectable)
    }

    @Test(
        "unselectableな日付を選択してもselectedDateとitemsは変更されない",
        arguments: [-33, -32, -31, 8, 9, 10]
    )
    func selectDate_unselectable(offsetFromAnchor: Int) throws {
        var sut = makeSut(selectedDate: Self.anchorDate, storagePolicy: .free)
        let originalSut = sut
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        sut.selectDate(targetDate, calendar: Self.calendar)
        #expect(sut == originalSut)
    }

}

private extension HouseworkDateListTest {

    func makeSut(selectedDate: Date, storagePolicy: HouseworkStoragePolicy) -> HouseworkDateList {
        HouseworkDateList(
            anchorDate: Self.anchorDate,
            selectedDate: selectedDate,
            calendar: Self.calendar,
            storagePolicy: storagePolicy
        )
    }

}
