//
//  HouseworkDateListTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import Foundation
import Testing
@testable import HometeDomain

struct HouseworkDateListTest {

    // anchorDate = 2026/04/15、selectedDate = 2026/04/15（= anchor当日）を基準にテスト
    // selectableOffset=7、unselectablePadding=3 → 合計 (7+3)*2+1 = 21件
    private static let calendar = Calendar.japanese
    private static let anchorDate = Date.previewDate(year: 2026, month: 4, day: 15)

    // MARK: - items

    @Test("有効範囲前後に3日ずつpadding追加した合計21件のアイテムリストを保持する")
    func items_count() {
        let sut = makeSut(selectedDate: Self.anchorDate)
        #expect(sut.items.count == 21)
    }

    @Test("アイテムリストの先頭日付はanchorDate-10から始まる")
    func items_firstDate() {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let expected = Self.calendar.date(
            byAdding: .day,
            value: -10,
            to: Self.calendar.startOfDay(for: Self.anchorDate)
        )
        #expect(sut.items.first?.date == expected)
    }

    @Test("アイテムリストの末尾日付はanchorDate+10で終わる")
    func items_lastDate() {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let expected = Self.calendar.date(
            byAdding: .day,
            value: 10,
            to: Self.calendar.startOfDay(for: Self.anchorDate)
        )
        #expect(sut.items.last?.date == expected)
    }

    @Test("アイテムリストの日付は1日刻みで連続している")
    func items_continuous() {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let dates = sut.items.map(\.date)
        let isConsecutive = zip(dates, dates.dropFirst()).allSatisfy { prev, next in
            Self.calendar.dateComponents([.day], from: prev, to: next).day == 1
        }
        #expect(isConsecutive)
    }

    // MARK: - state: selected

    @Test(
        "selectedDateと同じ日付のアイテム状態はselectedを返す",
        arguments: [
            Date.previewDate(year: 2026, month: 4, day: 15), // anchor当日
            Date.previewDate(year: 2026, month: 4, day: 12), // anchor-3（selectable範囲内）
            Date.previewDate(year: 2026, month: 4, day: 18)  // anchor+3（selectable範囲内）
        ]
    )
    func state_returns_selected(selectedDate: Date) {
        let sut = makeSut(selectedDate: selectedDate)
        let actual = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: selectedDate) }?.state
        #expect(actual == .selected)
    }

    // MARK: - state: selectable

    @Test(
        "anchorDate±7の範囲かつselected以外のアイテム状態はselectableを返す",
        arguments: [-7, -5, -3, -1, 1, 3, 5, 7] // 0はanchor=selectedなのでselectedになる
    )
    func state_returns_selectable(offsetFromAnchor: Int) async throws {
        let sut = makeSut(selectedDate: Self.anchorDate) // selectedDate = anchorDate（offset=0）
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        let actual = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: targetDate) }?.state
        #expect(actual == .selectable)
    }

    // MARK: - state: unselectable

    @Test(
        "anchorDate±7の範囲外のアイテム状態はunselectableを返す",
        arguments: [-10, -9, -8, 8, 9, 10]
    )
    func state_returns_unselectable(offsetFromAnchor: Int) async throws {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        let actual = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: targetDate) }?.state
        #expect(actual == .unselectable)
    }

    // MARK: - selectDate

    @Test(
        "selectableな日付を選択するとselectedDateが更新されその日付のアイテム状態がselectedになる",
        arguments: [-7, -3, -1, 1, 3, 7]
    )
    func selectDate_selectable(offsetFromAnchor: Int) async throws {
        var sut = makeSut(selectedDate: Self.anchorDate)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        sut.selectDate(targetDate, calendar: Self.calendar)
        let expectedSelectedDate = Self.calendar.startOfDay(for: targetDate)
        #expect(sut.selectedDate == expectedSelectedDate)
        let selectedItem = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: targetDate) }
        #expect(selectedItem?.state == .selected)
    }

    @Test(
        "selectableな日付を選択すると旧selectedDateのアイテム状態がselectableに変わる",
        arguments: [-7, -3, -1, 1, 3, 7]
    )
    func selectDate_previousSelected_becomes_selectable(offsetFromAnchor: Int) async throws {
        var sut = makeSut(selectedDate: Self.anchorDate)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        sut.selectDate(targetDate, calendar: Self.calendar)
        let prevSelectedItem = sut.items.first { Self.calendar.isDate($0.date, inSameDayAs: Self.anchorDate) }
        #expect(prevSelectedItem?.state == .selectable)
    }

    @Test(
        "unselectableな日付を選択してもselectedDateとitemsは変更されない",
        arguments: [-10, -9, -8, 8, 9, 10]
    )
    func selectDate_unselectable(offsetFromAnchor: Int) async throws {
        var sut = makeSut(selectedDate: Self.anchorDate)
        let originalSut = sut
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        sut.selectDate(targetDate, calendar: Self.calendar)
        #expect(sut == originalSut)
    }
}

private extension HouseworkDateListTest {

    func makeSut(selectedDate: Date) -> HouseworkDateList {
        HouseworkDateList(
            anchorDate: Self.anchorDate,
            selectedDate: selectedDate,
            calendar: Self.calendar
        )
    }
}
