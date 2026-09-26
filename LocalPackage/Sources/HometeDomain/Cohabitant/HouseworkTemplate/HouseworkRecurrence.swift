//
//  HouseworkRecurrence.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

/// テンプレートの家事の繰り返し方
public enum HouseworkRecurrence: Sendable, Hashable {

    /// 毎週（指定した曜日）
    case weekly(Set<DayOfWeek>)
    /// 毎月
    case monthly(MonthlyRecurrenceRule)

}
