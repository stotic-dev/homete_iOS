//
//  HouseworkContribution.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import HometeDomain

struct HouseworkContribution: Equatable {
    
    private(set) var list: [String: [PointOfDay]] = [:]
    
    static func make(by houseworkItems: [HouseworkItem], calendar: Calendar) -> Self {
        
        let completedItems = houseworkItems.filter { $0.state == .completed }
        let groupedByUserItems: [String: [HouseworkItem]] = Dictionary(
            grouping: completedItems
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
    
    func calculatePointSummaries(allUserIds: [String], month: Date, calendar: Calendar) -> [PointSummary] {
        
        return allUserIds.compactMap { userId in
            
            guard let targetList = list[userId]?.filter( {
                calendar.isDate($0.indexedDay, equalTo: month, toGranularity: .month)
            }) else {
                return PointSummary(
                    userId: userId,
                    monthlyPoint: .zero,
                    achievedCount: .zero
                )
            }
            
            let monthlyPoint = targetList.reduce(0) { $0 + $1.point.value }
            let achievedCount = targetList.count
            return PointSummary(
                userId: userId,
                monthlyPoint: monthlyPoint,
                achievedCount: achievedCount
            )
        }
    }
}
