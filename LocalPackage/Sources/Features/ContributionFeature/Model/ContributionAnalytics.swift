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
    ) async -> Self? {
        
        guard let dateRange = displayPeriod.calcDateRange(calendar: calendar) else { return nil }
        let (weekPointList, monthPointList, yearPointList) = await buildPointList(
            members: members,
            contribution: contribution,
            dateRange: dateRange,
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
    ) async -> Self? {
        
        guard let dateRange = displayPeriod.calcDateRange(calendar: calendar) else { return nil }
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
        let (weekPointList, monthPointList, yearPointList) = await Self.buildPointList(
            members: members,
            contribution: contribution,
            dateRange: dateRange,
            calendar: calendar
        )
        
        return .init(
            weekPointList: weekPointList,
            monthPointList: monthPointList,
            yearPointList: yearPointList,
            displayPeriod: displayPeriod
        )
    }
    
    func currentList(calendar: Calendar) -> AllUserViewablePointList? {

        guard let dateRange = displayPeriod.calcDateRange(calendar: calendar) else { return nil }
        return switch displayPeriod.type {

        case .week: .make(
            list: weekPointList,
            displayPeriod: displayPeriod.type,
            dateRange: dateRange,
            calendar: calendar
        )

        case .month: .make(
            list: monthPointList,
            displayPeriod: displayPeriod.type,
            dateRange: dateRange,
            calendar: calendar
        )

        case .year: .make(
            list: yearPointList,
            displayPeriod: displayPeriod.type,
            dateRange: dateRange,
            calendar: calendar
        )
        }
    }
}

private extension ContributionAnalytics {
    
    static func buildPointList(
        members: CohabitantMemberList,
        contribution: HouseworkContribution,
        dateRange: ClosedRange<Date>,
        calendar: Calendar
    ) async -> ( // swiftlint:disable:this large_tuple
        [PointOfWeek],
        [PointOfMonth],
        [PointOfYear]
    ) {
        
        async let weekPointList: [PointOfWeek] = Task.detached {
            contribution.viewablePointList(
                members: members,
                dateRange: dateRange,
                calendar: calendar
            )
        }.value
        
        async let monthPointList: [PointOfMonth] = Task.detached {
            contribution.viewablePointList(
                members: members,
                dateRange: dateRange,
                calendar: calendar
            )
        }.value
        
        async let yearPointList: [PointOfYear] = Task.detached {
            contribution.viewablePointList(
                members: members,
                dateRange: dateRange,
                calendar: calendar
            )
        }.value
        
        return await (weekPointList, monthPointList, yearPointList)
    }
}
