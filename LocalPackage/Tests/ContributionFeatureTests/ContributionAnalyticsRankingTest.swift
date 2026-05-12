//
//  ContributionAnalyticsRankingTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

@testable import ContributionFeature
import Foundation
import HometeDomain
import Testing

extension ContributionAnalyticsTest.RankingCase {

    @Test("displayPeriod.type=.weekで作ったanalyticsを、anchor固定でmonthへ切り替えるとmonth期間のランキングが返る")
    func ranking_afterTypeSwitchKeepingAnchor_usesNewPeriodPointList() async {
        // Arrange: 月間範囲には含まれるが週間範囲には含まれない日付にデータを置く
        let anchor = Date.previewDate(year: 2026, month: 4, day: 30)
        let dateOutsideWeek = Date.previewDate(year: 2026, month: 4, day: 10)
        let contribution = HouseworkContribution.makeForTest(
            list: [
                "u1": [.init(indexedDay: dateOutsideWeek, point: .init(value: 50))],
            ],
            calendar: calendar
        )
        let members = CohabitantMemberList(
            value: [.init(id: "u1", userName: "ユーザー1")],
            ownId: "u1"
        )
        let weekPeriod = DisplayPointPeriod(type: .week, anchor: anchor)
        let monthPeriod = DisplayPointPeriod(type: .month, anchor: anchor)
        let weekAnalytics = await ContributionAnalytics.make(
            contribution: contribution,
            members: members,
            displayPeriod: weekPeriod,
            calendar: calendar
        )
        let monthAnalytics = await weekAnalytics.updatePeriod(
            displayPeriod: monthPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )

        // Act
        let result = monthAnalytics.ranking(
            criterion: .point,
            myUserId: "u1",
            calendar: calendar
        )

        // Assert: 月間範囲のpointListに基づきtotalValue=50, denominator=月間日数
        let monthDayCount = monthPeriod.calcDatePeriod(calendar: calendar).count
        let expected: [ContributionAnalyticsRankItem] = [
            .init(
                rank: 1,
                userId: "u1",
                userName: "ユーザー1",
                isMe: true,
                totalValue: 50,
                averageValue: 50.0 / Double(monthDayCount)
            ),
        ]
        #expect(result == expected)
    }

    @Test("criterion=.point の場合はtotalポイント降順でランキングが返る")
    func ranking_byPoint_returnsDescendingOrder() {
        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 4, day: 26)
        let weekStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let period = DisplayPointPeriod(type: .week, anchor: anchor)
        let weekList: [PointOfWeek] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 14),
                totalAchievementCount: 7,
                elements: [],
                startDate: weekStart
            ),
            .init(
                userId: "u2",
                userName: "ユーザー2",
                total: .init(value: 70),
                totalAchievementCount: 14,
                elements: [],
                startDate: weekStart
            ),
        ]
        let analytics = ContributionAnalytics(
            weekPointList: weekList,
            monthPointList: [],
            yearPointList: [],
            displayPeriod: period
        )

        // Act
        let result = analytics.ranking(criterion: .point, myUserId: "u1", calendar: .japanese)

        // Assert
        let expected: [ContributionAnalyticsRankItem] = [
            .init(
                rank: 1,
                userId: "u2",
                userName: "ユーザー2",
                isMe: false,
                totalValue: 70,
                averageValue: 10.0
            ),
            .init(
                rank: 2,
                userId: "u1",
                userName: "ユーザー1",
                isMe: true,
                totalValue: 14,
                averageValue: 2.0
            ),
        ]
        #expect(result == expected)
    }

    @Test("criterion=.achievement の場合は達成数降順でランキングが返る")
    func ranking_byAchievement_returnsDescendingOrder() {
        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 4, day: 26)
        let weekStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let period = DisplayPointPeriod(type: .week, anchor: anchor)
        let weekList: [PointOfWeek] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 14),
                totalAchievementCount: 14,
                elements: [],
                startDate: weekStart
            ),
            .init(
                userId: "u2",
                userName: "ユーザー2",
                total: .init(value: 70),
                totalAchievementCount: 7,
                elements: [],
                startDate: weekStart
            ),
        ]
        let analytics = ContributionAnalytics(
            weekPointList: weekList,
            monthPointList: [],
            yearPointList: [],
            displayPeriod: period
        )

        // Act
        let result = analytics.ranking(criterion: .achievement, myUserId: "u1", calendar: .japanese)

        // Assert
        let expected: [ContributionAnalyticsRankItem] = [
            .init(
                rank: 1,
                userId: "u1",
                userName: "ユーザー1",
                isMe: true,
                totalValue: 14,
                averageValue: 2.0
            ),
            .init(
                rank: 2,
                userId: "u2",
                userName: "ユーザー2",
                isMe: false,
                totalValue: 7,
                averageValue: 1.0
            ),
        ]
        #expect(result == expected)
    }

    @Test("週表示の平均値はトータル / 7日 で算出される")
    func ranking_weekPeriod_dividesByDays() {
        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 4, day: 26)
        let weekStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let period = DisplayPointPeriod(type: .week, anchor: anchor)
        let weekList: [PointOfWeek] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 70),
                totalAchievementCount: 14,
                elements: [],
                startDate: weekStart
            ),
        ]
        let analytics = ContributionAnalytics(
            weekPointList: weekList,
            monthPointList: [],
            yearPointList: [],
            displayPeriod: period
        )

        // Act
        let result = analytics.ranking(criterion: .point, myUserId: "u1", calendar: .japanese)

        // Assert
        let expected: [ContributionAnalyticsRankItem] = [
            .init(
                rank: 1,
                userId: "u1",
                userName: "ユーザー1",
                isMe: true,
                totalValue: 70,
                averageValue: 10.0
            ),
        ]
        #expect(result == expected)
    }

    @Test("年表示の平均値はトータル / 12ヶ月 で算出される")
    func ranking_yearPeriod_dividesByMonths() {
        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 12, day: 31)
        let period = DisplayPointPeriod(type: .year, anchor: anchor)
        let yearList: [PointOfYear] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 240),
                totalAchievementCount: 24,
                elements: []
            ),
        ]
        let analytics = ContributionAnalytics(
            weekPointList: [],
            monthPointList: [],
            yearPointList: yearList,
            displayPeriod: period
        )

        // Act
        let result = analytics.ranking(criterion: .point, myUserId: "u1", calendar: .japanese)

        // Assert
        let expected: [ContributionAnalyticsRankItem] = [
            .init(
                rank: 1,
                userId: "u1",
                userName: "ユーザー1",
                isMe: true,
                totalValue: 240,
                averageValue: 20.0
            ),
        ]
        #expect(result == expected)
    }

    @Test("myUserIdに合致したユーザーのisMeがtrueになる")
    func ranking_marksMyUser_isMeTrue() {
        // Arrange
        let anchor = Date.previewDate(year: 2026, month: 4, day: 26)
        let weekStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let period = DisplayPointPeriod(type: .week, anchor: anchor)
        let weekList: [PointOfWeek] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 14),
                totalAchievementCount: 0,
                elements: [],
                startDate: weekStart
            ),
            .init(
                userId: "u2",
                userName: "ユーザー2",
                total: .init(value: 70),
                totalAchievementCount: 0,
                elements: [],
                startDate: weekStart
            ),
        ]
        let analytics = ContributionAnalytics(
            weekPointList: weekList,
            monthPointList: [],
            yearPointList: [],
            displayPeriod: period
        )

        // Act
        let result = analytics.ranking(criterion: .point, myUserId: "u2", calendar: .japanese)

        // Assert
        let expected: [ContributionAnalyticsRankItem] = [
            .init(
                rank: 1,
                userId: "u2",
                userName: "ユーザー2",
                isMe: true,
                totalValue: 70,
                averageValue: 10.0
            ),
            .init(
                rank: 2,
                userId: "u1",
                userName: "ユーザー1",
                isMe: false,
                totalValue: 14,
                averageValue: 2.0
            ),
        ]
        #expect(result == expected)
    }

}
