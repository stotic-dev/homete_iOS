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

    /// 完了した家事を、担当者ごとに配分されたポイントで集計する
    ///
    /// 複数人で担当した家事は、担当者それぞれに配分されたポイントと1件の達成を数える。
    static func make(by houseworkItems: [HouseworkItem], calendar: Calendar) -> Self {
        let contributions = houseworkItems
            .filter { $0.state == .completed }
            .flatMap { item in
                let indexedDay = calendar.startOfDay(for: item.indexedDate.value)
                return item.executors.map { executor in
                    ExecutorContribution(userId: executor.userId, indexedDay: indexedDay, point: executor.point)
                }
            }
        let groupedByUser = Dictionary(grouping: contributions, by: \.userId)
        let list: [String: [Date: PointOfDay]] = groupedByUser.mapValues { userContributions in
            Dictionary(grouping: userContributions, by: \.indexedDay).mapValues { dailyContributions in
                PointOfDay(
                    indexedDay: dailyContributions[0].indexedDay,
                    point: .init(value: dailyContributions.reduce(0) { $0 + $1.point }),
                    achievedCount: dailyContributions.count
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

private extension HouseworkContribution {

    /// 担当者1人分の、ある日の家事1件の実績
    struct ExecutorContribution {

        let userId: String
        let indexedDay: Date
        let point: Int

    }

}
