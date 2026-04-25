//
//  AllPointList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import HometeDomain

struct AllPointList: Equatable {
    
    private(set) var list: [String: [PointOfDay]] = [:]
    
    static func make(by houseworkItems: [HouseworkItem], calendar: Calendar) -> Self {
        
        let groupedByUserItems: [String: [HouseworkItem]] = Dictionary(
            grouping: houseworkItems.filter { $0.state == .completed }
        ) { $0.executorId ?? "" }
        let list: [String: [PointOfDay]] = groupedByUserItems.mapValues {
            $0.map { .init(indexedDay: $0.indexedDate.value, point: .init(value: $0.point)) }
        }
        return .init(list: list)
    }
    
    func viewablePointList(allUserIdList: [String], period: DateComponents, calendar: Calendar) -> [PointOfYear] {
        
        return allUserIdList.map {
            guard let userPointList = list[$0] else {
                return .init(
                    userId: $0,
                    displayPeriod: .init(type: .year, components: period),
                    total: .init(value: .zero),
                    elements: []
                )
            }
            return .make(
                by: userPointList,
                userId: $0,
                period: period,
                calendar: calendar
            )
        }
    }
    
    func viewablePointList(allUserIdList: [String], period: DateComponents, calendar: Calendar) -> [PointOfMonth] {
        
        return allUserIdList.map {
            guard let userPointList = list[$0] else {
                return .init(
                    userId: $0,
                    displayPeriod: .init(type: .month, components: period),
                    total: .init(value: .zero),
                    elements: []
                )
            }
            return .make(
                by: userPointList,
                userId: $0,
                period: period,
                calendar: calendar
            )
        }
    }
    
    func viewablePointList(allUserIdList: [String], period: DateComponents, calendar: Calendar) -> [PointOfWeek] {
        
        return allUserIdList.map {
            guard let userPointList = list[$0] else {
                return .init(
                    userId: $0,
                    displayPeriod: .init(type: .month, components: period),
                    total: .init(value: .zero),
                    elements: []
                )
            }
            return .make(
                by: userPointList,
                userId: $0,
                period: period,
                calendar: calendar
            )
        }
    }
}
