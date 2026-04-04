//
//  HouseworkDateScrollListTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import Foundation
import Testing
@testable import HometeDomain

struct HouseworkDateScrollListTest {

    // anchorDate = 2026/04/15、selectedDate = 2026/04/15（= anchor当日）を基準にテスト
    private static let calendar = Calendar.japanese
    private static let anchorDate = Date.dateComponents(year: 2026, month: 4, day: 15)

    // MARK: - dates

    @Test("有効範囲前後に3日ずつpadding追加した合計13日分の日付リストを返す")
    func dates_count() {
        let sut = makeSut(selectedDate: Self.anchorDate)
        #expect(sut.dates(calendar: Self.calendar).count == 13)
    }

    @Test("日付リストの先頭はanchorDate-6から始まる")
    func dates_firstDate() {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let expected = Self.calendar.date(
            byAdding: .day,
            value: -6,
            to: Self.calendar.startOfDay(for: Self.anchorDate)
        )
        #expect(sut.dates(calendar: Self.calendar).first == expected)
    }

    @Test("日付リストの末尾はanchorDate+6で終わる")
    func dates_lastDate() {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let expected = Self.calendar.date(
            byAdding: .day,
            value: 6,
            to: Self.calendar.startOfDay(for: Self.anchorDate)
        )
        #expect(sut.dates(calendar: Self.calendar).last == expected)
    }

    @Test("日付リストは1日刻みで連続している")
    func dates_continuous() {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let dates = sut.dates(calendar: Self.calendar)
        let isConsecutive = zip(dates, dates.dropFirst()).allSatisfy { prev, next in
            let diff = Self.calendar.dateComponents([.day], from: prev, to: next).day
            return diff == 1
        }
        #expect(isConsecutive)
    }

    // MARK: - state: selected

    @Test(
        "selectedDateと同じ日付の状態はselectedを返す",
        arguments: [
            Date.dateComponents(year: 2026, month: 4, day: 15), // anchor当日
            Date.dateComponents(year: 2026, month: 4, day: 12), // anchor-3
            Date.dateComponents(year: 2026, month: 4, day: 18)  // anchor+3
        ]
    )
    func state_returns_selected(selectedDate: Date) {
        let sut = makeSut(selectedDate: selectedDate)
        let actual = sut.state(for: selectedDate, calendar: Self.calendar)
        #expect(actual == .selected)
    }

    // MARK: - state: selectable

    @Test(
        "anchorDate±3の範囲かつselected以外の日付の状態はselectableを返す",
        arguments: [-3, -2, -1, 1, 2, 3] // 0はanchor=selectedなのでselectedになる
    )
    func state_returns_selectable(offsetFromAnchor: Int) async throws {
        // selectedDate = anchorDate なのでoffset=0はselected、他はselectable
        let sut = makeSut(selectedDate: Self.anchorDate)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        let actual = sut.state(for: targetDate, calendar: Self.calendar)
        #expect(actual == .selectable)
    }

    // MARK: - state: unselectable

    @Test(
        "anchorDate±3の範囲外の日付の状態はunselectableを返す",
        arguments: [-6, -5, -4, 4, 5, 6]
    )
    func state_returns_unselectable(offsetFromAnchor: Int) async throws {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        let actual = sut.state(for: targetDate, calendar: Self.calendar)
        #expect(actual == .unselectable)
    }

    // MARK: - selecting

    @Test(
        "selectableな日付を選択するとselectedDateがその日のstartOfDayに更新される",
        arguments: [-3, -1, 0, 1, 3]
    )
    func selecting_selectable(offsetFromAnchor: Int) async throws {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        let result = sut.selecting(targetDate, calendar: Self.calendar)
        let expectedSelectedDate = Self.calendar.startOfDay(for: targetDate)
        #expect(result.selectedDate == expectedSelectedDate)
    }

    @Test(
        "unselectableな日付を選択してもselectedDateは変更されない",
        arguments: [-6, -5, -4, 4, 5, 6]
    )
    func selecting_unselectable(offsetFromAnchor: Int) async throws {
        let sut = makeSut(selectedDate: Self.anchorDate)
        let targetDate = try #require(Self.calendar.date(byAdding: .day, value: offsetFromAnchor, to: Self.anchorDate))
        let result = sut.selecting(targetDate, calendar: Self.calendar)
        #expect(result.selectedDate == sut.selectedDate)
    }
}

private extension HouseworkDateScrollListTest {

    func makeSut(selectedDate: Date) -> HouseworkDateScrollList {
        HouseworkDateScrollList(
            anchorDate: Self.anchorDate,
            selectableOffset: 3,
            unselectablePadding: 3,
            selectedDate: selectedDate
        )
    }
}
