//
//  CalendarHelper.swift
//  homete
//
//  Created by Taichi Sato on 2026/01/17.
//

import Foundation

extension Calendar {
    static var japanese: Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .tokyo
        calendar.locale = .jp
        return calendar
    }
}
