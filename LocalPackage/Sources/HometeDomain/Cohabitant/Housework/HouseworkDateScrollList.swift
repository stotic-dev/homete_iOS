//
//  HouseworkDateScrollList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import Foundation

public struct HouseworkDateScrollList: Equatable {

    public let anchorDate: Date
    public let selectedDate: Date
    
    private static let selectableOffset = 7
    private static let unselectablePadding = 3

    public init(
        anchorDate: Date,
        selectedDate: Date
    ) {
        self.anchorDate = anchorDate
        self.selectedDate = selectedDate
    }

    /// 先頭padding日 + 選択可能範囲 + 末尾padding日 の全日付リスト（startOfDay正規化済み）
    public func dates(calendar: Calendar) -> [Date] {
        let anchorDay = calendar.startOfDay(for: anchorDate)
        let start = -(Self.selectableOffset + Self.unselectablePadding)
        let end = Self.selectableOffset + Self.unselectablePadding
        return (start...end).compactMap { calendar.date(byAdding: .day, value: $0, to: anchorDay) }
    }

    /// 指定した日付の状態を返す
    public func state(for date: Date, calendar: Calendar) -> HouseworkDateState {
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let dateDay = calendar.startOfDay(for: date)
        if selectedDay == dateDay { return .selected }
        return isSelectable(date, calendar: calendar) ? .selectable : .unselectable
    }

    /// selectableな日付を選択した新しいインスタンスを返す。unselectableな場合は変更なし。
    public func selecting(_ date: Date, calendar: Calendar) -> Self {
        guard isSelectable(date, calendar: calendar) else { return self }
        return HouseworkDateScrollList(
            anchorDate: anchorDate,
            selectedDate: calendar.startOfDay(for: date)
        )
    }
}

private extension HouseworkDateScrollList {

    func isSelectable(_ date: Date, calendar: Calendar) -> Bool {
        let anchorDay = calendar.startOfDay(for: anchorDate)
        let dateDay = calendar.startOfDay(for: date)
        guard let diff = calendar.dateComponents([.day], from: anchorDay, to: dateDay).day else {
            return false
        }
        return abs(diff) <= Self.selectableOffset
    }
}
