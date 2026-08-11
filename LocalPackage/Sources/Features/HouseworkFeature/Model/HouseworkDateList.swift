//
//  HouseworkDateList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import Foundation
import HometeDomain

struct HouseworkDateList: Equatable {

    struct Item: Equatable {

        let date: Date
        let state: HouseworkDateState

    }

    let anchorDate: Date
    private(set) var selectedDate: Date
    private(set) var items: [Item]
    /// 過去方向に選択できる日数。保存期間ポリシーによって変わる
    private let backwardSelectableDays: Int
    /// 保存期間の上限に達しているか。無料プランで上限日まで遡ったときにブロック表示を出す判断に使う
    let hasStorageLimit: Bool

    private static let forwardSelectableOffset = 7
    private static let unselectablePadding = 3
    /// プレミアムプランで一度に生成する過去日数の上限
    ///
    /// 過去方向は無制限だが、日付セルを無限に生成することはできないため区切りを設ける。
    /// 貢献度画面と異なり家事ボードは日々のタスク管理が主目的のため、この範囲で足りる想定。
    private static let premiumBackwardDays = 365

    init(
        anchorDate: Date = .now,
        selectedDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        storagePolicy: HouseworkStoragePolicy = .free
    ) {
        let selectedDay = calendar.startOfDay(for: selectedDate)
        self.anchorDate = anchorDate
        self.selectedDate = selectedDay
        backwardSelectableDays = storagePolicy.boardBackwardDays ?? Self.premiumBackwardDays
        hasStorageLimit = storagePolicy.boardBackwardDays != nil
        items = Self.buildItems(
            anchorDate: anchorDate,
            selectedDate: selectedDay,
            calendar: calendar,
            backwardSelectableDays: backwardSelectableDays
        )
    }

    /// selectableな日付を選択してitemsとselectedDateを更新する。unselectableな場合は変更なし。
    mutating func selectDate(_ date: Date, calendar: Calendar) {
        guard isSelectable(date, calendar: calendar) else { return }
        selectedDate = calendar.startOfDay(for: date)
        items = Self.buildItems(
            anchorDate: anchorDate,
            selectedDate: selectedDate,
            calendar: calendar,
            backwardSelectableDays: backwardSelectableDays
        )
    }

    /// 選択できる最古の日付
    func oldestSelectableDate(calendar: Calendar) -> Date? {
        let anchorDay = calendar.startOfDay(for: anchorDate)
        return calendar.date(byAdding: .day, value: -backwardSelectableDays, to: anchorDay)
    }

}

private extension HouseworkDateList {

    static func buildItems(
        anchorDate: Date,
        selectedDate: Date,
        calendar: Calendar,
        backwardSelectableDays: Int
    ) -> [Item] {
        let anchorDay = calendar.startOfDay(for: anchorDate)
        let start = -(backwardSelectableDays + unselectablePadding)
        let end = forwardSelectableOffset + unselectablePadding
        return (start ... end).compactMap { delta -> Item? in
            guard let date = calendar.date(byAdding: .day, value: delta, to: anchorDay) else { return nil }
            let state: HouseworkDateState = if date == selectedDate {
                .selected
            } else if isSelectableOffset(delta, backwardSelectableDays: backwardSelectableDays) {
                .selectable
            } else {
                .unselectable
            }
            return Item(date: date, state: state)
        }
    }

    static func isSelectableOffset(_ delta: Int, backwardSelectableDays: Int) -> Bool {
        delta >= 0 ? delta <= forwardSelectableOffset : -delta <= backwardSelectableDays
    }

    func isSelectable(_ date: Date, calendar: Calendar) -> Bool {
        let anchorDay = calendar.startOfDay(for: anchorDate)
        let dateDay = calendar.startOfDay(for: date)
        guard let diff = calendar.dateComponents([.day], from: anchorDay, to: dateDay).day else { return false }
        return Self.isSelectableOffset(diff, backwardSelectableDays: backwardSelectableDays)
    }

}
