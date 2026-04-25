//
//  AllPointList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import HometeDomain

struct AllPointList: Equatable {
    
    private(set) var list: [DayOfPoint] = []
    
    static func make(by houseworkItems: [HouseworkItem], calendar: Calendar) -> Self {
        
        let list: [DayOfPoint] = houseworkItems.compactMap {
            guard $0.state == .completed else { return nil }
            return .init(indexedDay: $0.indexedDate.value, point: .init(value: $0.point))
        }
        return .init(list: list)
    }
    
    func viewablePointList(period: DateComponents, calendar: Calendar) -> YearOfPoint {
        
        return .make(period: period, by: list, calendar: calendar)
    }
    
    func viewablePointList(period: DateComponents, calendar: Calendar) -> MonthOfPoint {
        
        return .make(period: period, by: list, calendar: calendar)
    }
    
    // TODO: Weekの生成メソッド実装後に定義
//    func viewablePointList(utilWeek: String) -> WeekOfPoint {
//        return .make(util: .year(value: utilYear), by: list)
//    }
}
