//
//  ContributionAnalyticsTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import Foundation
import Testing
import HometeDomain
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct ContributionAnalyticsTest {
    struct UpdatePeriodCase {
        private let calendar = Calendar.japanese
    }
    struct CurrentListCase {
        private let calendar = Calendar.japanese
    }
}

// MARK: - updatePeriod

extension ContributionAnalyticsTest.UpdatePeriodCase {

    @Test("anchorが同じ場合はpointListを再計算せずdisplayPeriodだけ更新される")
    func updatePeriod_sameAnchor_keepsExistingPointLists() async throws {

        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 4, day: 26)
        let weekPeriod = DisplayPointPeriod(type: .week, anchor: anchor)
        let monthPeriod = DisplayPointPeriod(type: .month, anchor: anchor)

        let weekStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let existingWeekList: [PointOfWeek] = [
            .init(userId: "u1", userName: "ユーザー1", total: .init(value: 100), elements: [], startDate: weekStart)
        ]
        let existingMonthList: [PointOfMonth] = [
            .init(userId: "u1", userName: "ユーザー1", total: .init(value: 200), elements: [], startDate: weekStart)
        ]
        let existingYearList: [PointOfYear] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 300),
                elements: []
            )
        ]
        let analytics = ContributionAnalytics(
            weekPointList: existingWeekList,
            monthPointList: existingMonthList,
            yearPointList: existingYearList,
            displayPeriod: weekPeriod
        )
        let contribution = HouseworkContribution()
        let members = CohabitantMemberList(value: [.init(id: "u1", userName: "ユーザー1")], ownId: "u1")

        // Act
        let result = await analytics.updatePeriod(
            displayPeriod: monthPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )

        // Assert: displayPeriodだけ変わり、pointListはそのまま保持される
        let expected = ContributionAnalytics(
            weekPointList: existingWeekList,
            monthPointList: existingMonthList,
            yearPointList: existingYearList,
            displayPeriod: monthPeriod
        )
        #expect(result == expected)
    }

    @Test("anchorが異なる場合はpointListが再計算される")
    func updatePeriod_differentAnchor_recalculatesPointLists() async throws {

        // Arrange
        let oldAnchor = Date.previewDate(year: 2026, month: 4, day: 26)
        let newAnchor = Date.previewDate(year: 2026, month: 5, day: 3)
        let oldPeriod = DisplayPointPeriod(type: .week, anchor: oldAnchor)
        let newPeriod = DisplayPointPeriod(type: .week, anchor: newAnchor)

        let oldStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let sentinelList: [PointOfWeek] = [
            .init(userId: "u1", userName: "ユーザー1", total: .init(value: 999), elements: [], startDate: oldStart)
        ]
        let analytics = ContributionAnalytics(
            weekPointList: sentinelList,
            monthPointList: [],
            yearPointList: [],
            displayPeriod: oldPeriod
        )
        let contribution = HouseworkContribution()
        let members = CohabitantMemberList(value: [.init(id: "u1", userName: "ユーザー1")], ownId: "u1")

        // Act
        let result = await analytics.updatePeriod(
            displayPeriod: newPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )

        // Assert: anchorが変わったのでpointListが再計算される（HouseworkContributionが空なのでポイントはゼロ）
        let newWeekStart = Date.previewDate(year: 2026, month: 4, day: 27)
        #expect(result.displayPeriod == newPeriod)
        #expect(result.weekPointList.first?.userId == "u1")
        #expect(result.weekPointList.first?.total.value == 0)
        #expect(result.weekPointList.first?.startDate == newWeekStart)
        #expect(result.monthPointList.first?.total.value == 0)
        #expect(result.yearPointList.first?.total.value == 0)
        // sentinelListが入れ替わっていることの確認
        #expect(result.weekPointList.first?.total.value != 999)
    }
}

// MARK: - currentList

extension ContributionAnalyticsTest.CurrentListCase {

    @Test("week表示のときweekPointListに基づくAllUserViewablePointListが返る")
    func currentList_weekPeriod_returnsWeekBasedList() throws {

        // Arrange
        let anchor   = Date.previewDate(year: 2026, month: 4, day: 26)
        let weekStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let period   = DisplayPointPeriod(type: .week, anchor: anchor)
        let weekList: [PointOfWeek] = [
            .init(userId: "u1", userName: "ユーザー1", total: .init(value: 50), elements: [], startDate: weekStart)
        ]
        let analytics = ContributionAnalytics(
            weekPointList: weekList,
            monthPointList: [],
            yearPointList: [],
            displayPeriod: period
        )

        // Act
        let result = analytics.currentList(calendar: calendar)

        // Assert
        let expected = AllUserViewablePointList(
            list: [.init(userId: "u1", userName: "ユーザー1", total: .init(value: 50), elements: [])],
            displayPeriod: .week
        )
        #expect(result == expected)
    }

    @Test("month表示のときmonthPointListに基づくAllUserViewablePointListが返る")
    func currentList_monthPeriod_returnsMonthBasedList() throws {

        // Arrange
        let anchor      = Date.previewDate(year: 2026, month: 4, day: 30)
        let monthStart  = Date.previewDate(year: 2026, month: 3, day: 31)
        let period      = DisplayPointPeriod(type: .month, anchor: anchor)
        let monthList: [PointOfMonth] = [
            .init(userId: "u1", userName: "ユーザー1", total: .init(value: 80), elements: [], startDate: monthStart)
        ]
        let analytics = ContributionAnalytics(
            weekPointList: [],
            monthPointList: monthList,
            yearPointList: [],
            displayPeriod: period
        )

        // Act
        let result = analytics.currentList(calendar: calendar)

        // Assert
        let expected = AllUserViewablePointList(
            list: [.init(userId: "u1", userName: "ユーザー1", total: .init(value: 80), elements: [])],
            displayPeriod: .month
        )
        #expect(result == expected)
    }

    @Test("year表示のときyearPointListに基づくAllUserViewablePointListが返る")
    func currentList_yearPeriod_returnsYearBasedList() throws {

        // Arrange
        let anchor    = Date.previewDate(year: 2026, month: 12, day: 31)
        let period    = DisplayPointPeriod(type: .year, anchor: anchor)
        let yearList: [PointOfYear] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 500),
                elements: []
            )
        ]
        let analytics = ContributionAnalytics(
            weekPointList: [],
            monthPointList: [],
            yearPointList: yearList,
            displayPeriod: period
        )

        // Act
        let result = analytics.currentList(calendar: calendar)

        // Assert
        let expected = AllUserViewablePointList(
            list: [.init(userId: "u1", userName: "ユーザー1", total: .init(value: 500), elements: [])],
            displayPeriod: .year
        )
        #expect(result == expected)
    }
}
