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
    private(set) var thanksItemsByUser: [String: [Date]] = [:]

    static func make(by houseworkItems: [HouseworkItem], calendar: Calendar) -> Self {

        let completedItems = houseworkItems.filter { $0.state == .completed }
        let groupedByUserItems: [String: [HouseworkItem]] = Dictionary(
            grouping: completedItems
        ) { $0.executorId ?? "" }
        let list: [String: [PointOfDay]] = groupedByUserItems.mapValues {
            $0.map { .init(indexedDay: $0.indexedDate.value, point: .init(value: $0.point)) }
        }
        let thanksItemsByUser: [String: [Date]] = groupedByUserItems
            .mapValues { $0.filter { $0.reviewerId != nil }.map(\.indexedDate.value) }
            .filter { !$0.value.isEmpty }
        return .init(list: list, thanksItemsByUser: thanksItemsByUser)
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
        return allUserIds.map { userId in
            let monthlyPoint = list[userId]?
                .filter { calendar.isDate($0.indexedDay, equalTo: month, toGranularity: .month) }
                .reduce(0) { $0 + $1.point.value } ?? 0
            let thanksCount = thanksItemsByUser[userId]?
                .filter { calendar.isDate($0, equalTo: month, toGranularity: .month) }
                .count ?? 0
            return PointSummary(userId: userId, monthlyPoint: monthlyPoint, thanksCount: thanksCount)
        }
    }
}
