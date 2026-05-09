//
//  ContributionAnalytics.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import Foundation
import HometeDomain

struct ContributionAnalytics: Equatable {
    
    let weekPointList: [PointOfWeek]
    let monthPointList: [PointOfMonth]
    let yearPointList: [PointOfYear]
    /// 表示区間
    let displayPeriod: DisplayPointPeriod

    static func make(
        contribution: HouseworkContribution,
        members: CohabitantMemberList,
        displayPeriod: DisplayPointPeriod,
        calendar: Calendar
    ) async -> Self {
        
        let periodDates = displayPeriod.calcDatePeriod(calendar: calendar)
        let (weekPointList, monthPointList, yearPointList) = await buildPointList(
            members: members,
            contribution: contribution,
            dates: periodDates,
            calendar: calendar
        )
        
        return .init(
            weekPointList: weekPointList,
            monthPointList: monthPointList,
            yearPointList: yearPointList,
            displayPeriod: displayPeriod
        )
    }
    
    func updatePeriod(
        displayPeriod: DisplayPointPeriod,
        members: CohabitantMemberList,
        contribution: HouseworkContribution,
        calendar: Calendar
    ) async -> Self {
        
        guard self.displayPeriod.anchor != displayPeriod.anchor else {
            
            // 基準日が変わっていない場合は別の期間のpointListは計算済みなので、指定期間だけ更新する
            return .init(
                weekPointList: weekPointList,
                monthPointList: monthPointList,
                yearPointList: yearPointList,
                displayPeriod: displayPeriod
            )
        }
        
        // 基準日が変わった場合はpointListを入れ替える必要があるので更新する
        let periodDates = displayPeriod.calcDatePeriod(calendar: calendar)
        let (weekPointList, monthPointList, yearPointList) = await Self.buildPointList(
            members: members,
            contribution: contribution,
            dates: periodDates,
            calendar: calendar
        )
        
        return .init(
            weekPointList: weekPointList,
            monthPointList: monthPointList,
            yearPointList: yearPointList,
            displayPeriod: displayPeriod
        )
    }
    
    func currentList(calendar: Calendar) -> AllUserViewablePointList {

        return switch displayPeriod.type {

        case .week: .make(
            list: weekPointList,
            displayPeriod: displayPeriod.type
        )

        case .month: .make(
            list: monthPointList,
            displayPeriod: displayPeriod.type
        )

        case .year: .make(
            list: yearPointList,
            displayPeriod: displayPeriod.type
        )
        }
    }
    
    /// 指定期間中のユーザー毎の家事達成情報
    func achieved() -> [UserHouseworkAchieved] {

        switch displayPeriod.type {
        case .week:
            weekPointList.map {
                .init(userId: $0.userId, userName: $0.userName, achievedCount: $0.totalAchievementCount)
            }

        case .month: monthPointList.map {
            .init(userId: $0.userId, userName: $0.userName, achievedCount: $0.totalAchievementCount)
        }

        case .year: yearPointList.map {
            .init(userId: $0.userId, userName: $0.userName, achievedCount: $0.totalAchievementCount)
        }
        }
    }

    /// 指定期間中の貢献度を criterion 順でランキング化する
    func ranking(
        criterion: ContributionAnalyticsRankingCriterion,
        myUserId: String,
        calendar: Calendar
    ) -> [ContributionAnalyticsRankItem] {

        let denominator = max(displayPeriod.calcDatePeriod(calendar: calendar).count, 1)
        let sortedEntries = userTotals(criterion: criterion)
            .sorted { $0.totalValue > $1.totalValue }

        var items: [ContributionAnalyticsRankItem] = []
        for (index, entry) in sortedEntries.enumerated() {
            let item = ContributionAnalyticsRankItem(
                rank: index + 1,
                userId: entry.userId,
                userName: entry.userName,
                isMe: entry.userId == myUserId,
                totalValue: entry.totalValue,
                averageValue: Double(entry.totalValue) / Double(denominator)
            )
            items.append(item)
        }
        return items
    }
}

private extension ContributionAnalytics {

    struct UserTotalEntry {
        let userId: String
        let userName: String
        let totalValue: Int
    }

    func userTotals(criterion: ContributionAnalyticsRankingCriterion) -> [UserTotalEntry] {

        switch displayPeriod.type {
        case .week:
            return weekPointList.map {
                .init(
                    userId: $0.userId,
                    userName: $0.userName,
                    totalValue: criterion == .point ? $0.total.value : $0.totalAchievementCount
                )
            }

        case .month:
            return monthPointList.map {
                .init(
                    userId: $0.userId,
                    userName: $0.userName,
                    totalValue: criterion == .point ? $0.total.value : $0.totalAchievementCount
                )
            }

        case .year:
            return yearPointList.map {
                .init(
                    userId: $0.userId,
                    userName: $0.userName,
                    totalValue: criterion == .point ? $0.total.value : $0.totalAchievementCount
                )
            }
        }
    }

    static func buildPointList(
        members: CohabitantMemberList,
        contribution: HouseworkContribution,
        dates: [Date],
        calendar: Calendar
    ) async -> ( // swiftlint:disable:this large_tuple
        [PointOfWeek],
        [PointOfMonth],
        [PointOfYear]
    ) {
        
        async let weekPointList: [PointOfWeek] = Task.detached {
            contribution.viewablePointList(
                members: members,
                dates: dates,
                calendar: calendar
            )
        }.value
        
        async let monthPointList: [PointOfMonth] = Task.detached {
            contribution.viewablePointList(
                members: members,
                dates: dates,
                calendar: calendar
            )
        }.value
        
        async let yearPointList: [PointOfYear] = Task.detached {
            contribution.viewablePointList(
                members: members,
                dates: dates,
                calendar: calendar
            )
        }.value
        
        return await (weekPointList, monthPointList, yearPointList)
    }
}
