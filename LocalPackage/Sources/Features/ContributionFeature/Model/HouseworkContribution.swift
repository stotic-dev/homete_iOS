//
//  HouseworkContribution.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import HometeDomain

public struct HouseworkContribution: Equatable, Sendable {

    /// userId -> (startOfDay -> その日の集約済みPointOfDay)
    private(set) var list: [String: [Date: PointOfDay]] = [:]

    /// 全ユーザーの中で家事を達成した最新の日付。データが無い場合はnil
    var latestAchievedDate: Date? {
        list.values.flatMap(\.values).map(\.indexedDay).max()
    }

    static func make(by houseworkItems: [HouseworkItem], calendar: Calendar) -> Self {
        let completedItems = houseworkItems.filter { $0.state == .completed }
        let groupedByUserItems: [String: [HouseworkItem]] = Dictionary(
            grouping: completedItems
        ) { $0.executorId ?? "" }
        let list: [String: [Date: PointOfDay]] = groupedByUserItems.mapValues { items in
            let groupedByDate = Dictionary(grouping: items) { item in
                calendar.startOfDay(for: item.indexedDate.value)
            }
            return groupedByDate.mapValues { dailyItems in
                let totalPoint = dailyItems.reduce(0) { $0 + $1.point }
                let indexedDay = calendar.startOfDay(for: dailyItems[0].indexedDate.value)
                return PointOfDay(
                    indexedDay: indexedDay,
                    point: .init(value: totalPoint),
                    achievedCount: dailyItems.count
                )
            }
        }

        return .init(list: list)
    }

    func viewablePointList(
        members: CohabitantMemberList,
        dates: [Date],
        calendar: Calendar
    ) -> [PointOfYear] {
        members.value.map { member in
            .make(
                by: list[member.id] ?? [:],
                userId: member.id,
                userName: member.userName,
                dates: dates,
                calendar: calendar
            )
        }
    }

    func viewablePointList(
        members: CohabitantMemberList,
        dates: [Date],
        calendar: Calendar
    ) -> [PointOfMonth] {
        members.value.map { member in
            .make(
                by: list[member.id] ?? [:],
                userId: member.id,
                userName: member.userName,
                dates: dates,
                calendar: calendar
            )
        }
    }

    func viewablePointList(
        members: CohabitantMemberList,
        dates: [Date],
        calendar: Calendar
    ) -> [PointOfWeek] {
        members.value.map { member in
            .make(
                by: list[member.id] ?? [:],
                userId: member.id,
                userName: member.userName,
                dates: dates,
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
        let userItems: [UserPointSummary] = members.value
            .compactMap { member in
                guard let userMap = list[member.id] else {
                    return UserPointSummary(
                        userId: member.id,
                        userName: member.userName,
                        isMe: member.id == myUserId,
                        monthlyPoint: .init(value: .zero),
                        achievedCount: .zero
                    )
                }

                let targetList = userMap.values.filter {
                    calendar.isDate($0.indexedDay, equalTo: month, toGranularity: .month)
                }

                let monthlyPoint = targetList.reduce(0) { $0 + $1.point.value }
                let achievedCount = targetList.reduce(0) { $0 + $1.achievedCount }
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
