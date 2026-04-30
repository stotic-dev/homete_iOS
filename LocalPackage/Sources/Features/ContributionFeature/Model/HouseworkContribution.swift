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
    
    func viewablePointList(
        members: CohabitantMemberList,
        dateRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> [PointOfYear] {

        return members.value.map { member in
            guard let userPointList = list[member.id] else {
                return .init(
                    userId: member.id,
                    userName: member.userName,
                    displayPeriod: .year,
                    total: .init(value: .zero),
                    elements: [],
                    dateRange: dateRange
                )
            }
            return .make(
                by: userPointList,
                userId: member.id,
                userName: member.userName,
                dateRange: dateRange,
                calendar: calendar
            )
        }
    }

    func viewablePointList(
        members: CohabitantMemberList,
        dateRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> [PointOfMonth] {

        return members.value.map { member in
            guard let userPointList = list[member.id] else {
                return .init(
                    userId: member.id,
                    userName: member.userName,
                    displayPeriod: .month,
                    total: .init(value: .zero),
                    elements: []
                )
            }
            return .make(
                by: userPointList,
                userId: member.id,
                userName: member.userName,
                dateRange: dateRange,
                calendar: calendar
            )
        }
    }

    func viewablePointList(
        members: CohabitantMemberList,
        dateRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> [PointOfWeek] {

        return members.value.map { member in
            guard let userPointList = list[member.id] else {
                return .init(
                    userId: member.id,
                    userName: member.userName,
                    displayPeriod: .week,
                    total: .init(value: .zero),
                    elements: []
                )
            }
            return .make(
                by: userPointList,
                userId: member.id,
                userName: member.userName,
                dateRange: dateRange,
                calendar: calendar
            )
        }
    }
    
    func calculatePointSummaries(
        month: Date,
        calendar: Calendar,
        members: CohabitantMemberList,
        myUserId: String
    ) -> AllUserPointSummary {

        let userItems: [UserPointSummary] = members.value.compactMap { member in

            guard let targetList = list[member.id]?.filter({
                calendar.isDate($0.indexedDay, equalTo: month, toGranularity: .month)
            }) else {
                return UserPointSummary(
                    userId: member.id,
                    userName: member.userName,
                    isMe: member.id == myUserId,
                    monthlyPoint: .init(value: .zero),
                    achievedCount: .zero
                )
            }

            let monthlyPoint = targetList.reduce(0) { $0 + $1.point.value }
            let achievedCount = targetList.count
            return UserPointSummary(
                userId: member.id,
                userName: member.userName,
                isMe: member.id == myUserId,
                monthlyPoint: .init(value: monthlyPoint),
                achievedCount: achievedCount
            )
        }

        return .init(items: userItems)
    }
}
