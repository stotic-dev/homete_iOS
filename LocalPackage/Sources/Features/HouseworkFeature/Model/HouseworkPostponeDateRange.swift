//
//  HouseworkPostponeDateRange.swift
//  LocalPackage
//

import Foundation

/// 家事詳細から別の日へまわすときに、選べる日付の範囲と最初に選んでおく日
///
/// 選べるのは今日から、家事ボードで選べる最も先の日まで。過去へはまわせない。
/// 家事の今の日付は範囲に入っても選べない（まわしても何も変わらないため）。
struct HouseworkPostponeDateRange: Equatable {

    /// 選べる日付の範囲（両端の日の0時）
    let selectableRange: ClosedRange<Date>
    /// 最初に選んでおく日。家事の日付の翌日を範囲に収めたもの
    let initialDate: Date
    /// 家事の今の日付（0時）
    let currentDate: Date

}

extension HouseworkPostponeDateRange {

    init(itemDate: Date, now: Date, calendar: Calendar) {
        let today = calendar.startOfDay(for: now)
        let newest = calendar.date(byAdding: .day, value: HouseworkDateList.forwardSelectableOffset, to: today) ?? today
        let itemDay = calendar.startOfDay(for: itemDate)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: itemDay) ?? itemDay
        self.init(
            selectableRange: today ... newest,
            initialDate: min(max(nextDay, today), newest),
            currentDate: itemDay
        )
    }

    /// その日へまわせるか
    func canPostpone(to date: Date, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: date)
        return selectableRange.contains(day) && day != currentDate
    }

}
