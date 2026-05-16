//
//  DayOfWeek.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import Foundation

/// HouseworkTemplateDay.dayOfWeek の値（0=日曜, 6=土曜）を UI から扱いやすくするための enum。
enum DayOfWeek: Int, CaseIterable, Identifiable, Hashable {

    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var id: Int {
        rawValue
    }

    /// 月曜始まりの表示順
    static let displayOrdered: [DayOfWeek] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
    ]

    var fullLabel: String {
        switch self {
        case .sunday: "日曜日"
        case .monday: "月曜日"
        case .tuesday: "火曜日"
        case .wednesday: "水曜日"
        case .thursday: "木曜日"
        case .friday: "金曜日"
        case .saturday: "土曜日"
        }
    }

}
