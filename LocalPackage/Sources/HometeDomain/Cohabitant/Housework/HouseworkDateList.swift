//
//  HouseworkDateScrollList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import Foundation

public struct HouseworkDateList: Equatable {

    public struct Item: Equatable {
        public let date: Date
        public let state: HouseworkDateState
    }

    public let anchorDate: Date
    public private(set) var selectedDate: Date
    public private(set) var items: [Item]

    private static let selectableOffset = 7
    private static let unselectablePadding = 3

    public init(anchorDate: Date = .now, selectedDate: Date = .now, calendar: Calendar = .autoupdatingCurrent) {
        let selectedDay = calendar.startOfDay(for: selectedDate)
        self.anchorDate = anchorDate
        self.selectedDate = selectedDay
        self.items = Self.buildItems(anchorDate: anchorDate, selectedDate: selectedDay, calendar: calendar)
    }

    /// selectableな日付を選択してitemsとselectedDateを更新する。unselectableな場合は変更なし。
    public mutating func selectDate(_ date: Date, calendar: Calendar) {
        guard isSelectable(date, calendar: calendar) else { return }
        selectedDate = calendar.startOfDay(for: date)
        items = Self.buildItems(anchorDate: anchorDate, selectedDate: selectedDate, calendar: calendar)
    }
}

private extension HouseworkDateList {

    static func buildItems(anchorDate: Date, selectedDate: Date, calendar: Calendar) -> [Item] {
        let anchorDay = calendar.startOfDay(for: anchorDate)
        let start = -(selectableOffset + unselectablePadding)
        let end = selectableOffset + unselectablePadding
        return (start...end).compactMap { delta -> Item? in
            guard let date = calendar.date(byAdding: .day, value: delta, to: anchorDay) else { return nil }
            let state: HouseworkDateState
            if date == selectedDate {
                state = .selected
            } else if abs(delta) <= selectableOffset {
                state = .selectable
            } else {
                state = .unselectable
            }
            return Item(date: date, state: state)
        }
    }

    func isSelectable(_ date: Date, calendar: Calendar) -> Bool {
        let anchorDay = calendar.startOfDay(for: anchorDate)
        let dateDay = calendar.startOfDay(for: date)
        guard let diff = calendar.dateComponents([.day], from: anchorDay, to: dateDay).day else { return false }
        return abs(diff) <= Self.selectableOffset
    }
}
