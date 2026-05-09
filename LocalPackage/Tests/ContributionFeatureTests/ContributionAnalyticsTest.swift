//
//  ContributionAnalyticsTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

// swiftlint:disable file_length

import Foundation
import Testing
import HometeDomain
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct ContributionAnalyticsTest {
    struct MakeCase {
        let calendar = Calendar.japanese
    }
    struct UpdatePeriodCase {
        private let calendar = Calendar.japanese
    }
    struct CurrentListCase {
        private let calendar = Calendar.japanese
    }
    struct RankingCase {
        let calendar = Calendar.japanese
    }
    struct IsEmptyCase {}
}

// MARK: - make

extension ContributionAnalyticsTest.MakeCase {

    @Test("displayPeriod.type=.monthで作ったanalyticsでも、week期間に切り替えると週間範囲のデータのみが集計される")
    func make_typeMonth_thenSwitchToWeek_usesWeekDates() async throws {

        // Arrange: 月間範囲には含まれるが週間範囲には含まれない日付にデータを置く
        let anchor = Date.previewDate(year: 2026, month: 4, day: 30)
        let dateOutsideWeek = Date.previewDate(year: 2026, month: 4, day: 10)
        let contribution = HouseworkContribution.makeForTest(
            list: [
                "u1": [.init(indexedDay: dateOutsideWeek, point: .init(value: 50))]
            ],
            calendar: calendar
        )
        let members = CohabitantMemberList(
            value: [.init(id: "u1", userName: "ユーザー1")],
            ownId: "u1"
        )
        let monthPeriod = DisplayPointPeriod(type: .month, anchor: anchor)
        let weekPeriod = DisplayPointPeriod(type: .week, anchor: anchor)
        let analytics = await ContributionAnalytics.make(
            contribution: contribution,
            members: members,
            displayPeriod: monthPeriod,
            calendar: calendar
        )

        // Act: anchorを変えずにtypeだけweekへ切り替える
        let result = await analytics.updatePeriod(
            displayPeriod: weekPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )

        // Assert: 週間範囲には04-10が含まれないので達成数0
        let expected: [UserHouseworkAchieved] = [
            .init(userId: "u1", userName: "ユーザー1", achievedCount: 0)
        ]
        #expect(result.achieved() == expected)
    }

    @Test("displayPeriod.type=.weekで作ったanalyticsでも、month期間に切り替えると月間範囲のデータが集計される")
    func make_typeWeek_thenSwitchToMonth_usesMonthDates() async throws {

        // Arrange: 月間範囲には含まれるが週間範囲には含まれない日付にデータを置く
        let anchor = Date.previewDate(year: 2026, month: 4, day: 30)
        let dateOutsideWeek = Date.previewDate(year: 2026, month: 4, day: 10)
        let contribution = HouseworkContribution.makeForTest(
            list: [
                "u1": [.init(indexedDay: dateOutsideWeek, point: .init(value: 50))]
            ],
            calendar: calendar
        )
        let members = CohabitantMemberList(
            value: [.init(id: "u1", userName: "ユーザー1")],
            ownId: "u1"
        )
        let weekPeriod = DisplayPointPeriod(type: .week, anchor: anchor)
        let monthPeriod = DisplayPointPeriod(type: .month, anchor: anchor)
        let analytics = await ContributionAnalytics.make(
            contribution: contribution,
            members: members,
            displayPeriod: weekPeriod,
            calendar: calendar
        )

        // Act: anchorを変えずにtypeだけmonthへ切り替える
        let result = await analytics.updatePeriod(
            displayPeriod: monthPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )

        // Assert: 月間範囲には04-10が含まれるので達成数1
        let expected: [UserHouseworkAchieved] = [
            .init(userId: "u1", userName: "ユーザー1", achievedCount: 1)
        ]
        #expect(result.achieved() == expected)
    }

    @Test("displayPeriod.type=.monthで作ったanalyticsでも、year期間に切り替えると年間範囲のデータが集計される")
    func make_typeMonth_thenSwitchToYear_usesYearDates() async throws {

        // Arrange: 年間範囲には含まれるが月間範囲には含まれない日付にデータを置く
        let anchor = Date.previewDate(year: 2026, month: 4, day: 30)
        let dateOutsideMonth = Date.previewDate(year: 2025, month: 8, day: 15)
        let contribution = HouseworkContribution.makeForTest(
            list: [
                "u1": [.init(indexedDay: dateOutsideMonth, point: .init(value: 50))]
            ],
            calendar: calendar
        )
        let members = CohabitantMemberList(
            value: [.init(id: "u1", userName: "ユーザー1")],
            ownId: "u1"
        )
        let monthPeriod = DisplayPointPeriod(type: .month, anchor: anchor)
        let yearPeriod = DisplayPointPeriod(type: .year, anchor: anchor)
        let analytics = await ContributionAnalytics.make(
            contribution: contribution,
            members: members,
            displayPeriod: monthPeriod,
            calendar: calendar
        )

        // Act: anchorを変えずにtypeだけyearへ切り替える
        let result = await analytics.updatePeriod(
            displayPeriod: yearPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )

        // Assert: 年間範囲には2025-08-15が含まれるので達成数1
        let expected: [UserHouseworkAchieved] = [
            .init(userId: "u1", userName: "ユーザー1", achievedCount: 1)
        ]
        #expect(result.achieved() == expected)
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
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 100),
                totalAchievementCount: 0,
                elements: [],
                startDate: weekStart
            )
        ]
        let existingMonthList: [PointOfMonth] = [
            // swiftlint:disable:next line_length
            .init(userId: "u1", userName: "ユーザー1", total: .init(value: 200), totalAchievementCount: 0, elements: [], startDate: weekStart)
        ]
        let existingYearList: [PointOfYear] = [
            .init(userId: "u1", userName: "ユーザー1", total: .init(value: 300), totalAchievementCount: 0, elements: [])
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
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 999),
                totalAchievementCount: 0,
                elements: [],
                startDate: oldStart
            )
        ]
        let analytics = ContributionAnalytics(
            weekPointList: sentinelList,
            monthPointList: [],
            yearPointList: [],
            displayPeriod: oldPeriod
        )
        // メンバーを空にして再計算結果を空配列に固定し、sentinelListが入れ替わったことを比較で検証する
        let contribution = HouseworkContribution()
        let members = CohabitantMemberList(value: [], ownId: "u1")

        // Act
        let result = await analytics.updatePeriod(
            displayPeriod: newPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )

        // Assert: anchorが変わったのでpointListが再計算され、sentinelListが空のリストに入れ替わる
        let expected = ContributionAnalytics(
            weekPointList: [],
            monthPointList: [],
            yearPointList: [],
            displayPeriod: newPeriod
        )
        #expect(result == expected)
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
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 50),
                totalAchievementCount: 0,
                elements: [],
                startDate: weekStart
            )
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
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 80),
                totalAchievementCount: 0,
                elements: [],
                startDate: monthStart
            )
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
                totalAchievementCount: 0,
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

// MARK: - isEmpty

extension ContributionAnalyticsTest.IsEmptyCase {

    @Test("週表示で全メンバーのtotalAchievementCountが0ならisEmptyはtrue")
    func isEmpty_week_allZero_returnsTrue() {

        // Arrange
        let weekStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let weekList: [PointOfWeek] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 0),
                totalAchievementCount: 0,
                elements: [],
                startDate: weekStart
            ),
            .init(
                userId: "u2",
                userName: "ユーザー2",
                total: .init(value: 0),
                totalAchievementCount: 0,
                elements: [],
                startDate: weekStart
            )
        ]
        let analytics = ContributionAnalytics(
            weekPointList: weekList,
            monthPointList: [],
            yearPointList: [],
            displayPeriod: .init(type: .week, anchor: Date.previewDate(year: 2026, month: 4, day: 26))
        )

        // Act & Assert
        #expect(analytics.isEmpty == true)
    }

    @Test("週表示でいずれかのメンバーが家事を達成していればisEmptyはfalse")
    func isEmpty_week_someAchieved_returnsFalse() {

        // Arrange
        let weekStart = Date.previewDate(year: 2026, month: 4, day: 20)
        let weekList: [PointOfWeek] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 0),
                totalAchievementCount: 0,
                elements: [],
                startDate: weekStart
            ),
            .init(
                userId: "u2",
                userName: "ユーザー2",
                total: .init(value: 30),
                totalAchievementCount: 1,
                elements: [],
                startDate: weekStart
            )
        ]
        let analytics = ContributionAnalytics(
            weekPointList: weekList,
            monthPointList: [],
            yearPointList: [],
            displayPeriod: .init(type: .week, anchor: Date.previewDate(year: 2026, month: 4, day: 26))
        )

        // Act & Assert
        #expect(analytics.isEmpty == false)
    }

    @Test("月表示で全メンバーのtotalAchievementCountが0ならisEmptyはtrue")
    func isEmpty_month_allZero_returnsTrue() {

        // Arrange
        let startDate = Date.previewDate(year: 2026, month: 4, day: 1)
        let monthList: [PointOfMonth] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 0),
                totalAchievementCount: 0,
                elements: [],
                startDate: startDate
            )
        ]
        let analytics = ContributionAnalytics(
            weekPointList: [],
            monthPointList: monthList,
            yearPointList: [],
            displayPeriod: .init(type: .month, anchor: Date.previewDate(year: 2026, month: 4, day: 30))
        )

        // Act & Assert
        #expect(analytics.isEmpty == true)
    }

    @Test("月表示でいずれかのメンバーが家事を達成していればisEmptyはfalse")
    func isEmpty_month_someAchieved_returnsFalse() {

        // Arrange
        let startDate = Date.previewDate(year: 2026, month: 4, day: 1)
        let monthList: [PointOfMonth] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 50),
                totalAchievementCount: 2,
                elements: [],
                startDate: startDate
            )
        ]
        let analytics = ContributionAnalytics(
            weekPointList: [],
            monthPointList: monthList,
            yearPointList: [],
            displayPeriod: .init(type: .month, anchor: Date.previewDate(year: 2026, month: 4, day: 30))
        )

        // Act & Assert
        #expect(analytics.isEmpty == false)
    }

    @Test("年表示で全メンバーのtotalAchievementCountが0ならisEmptyはtrue")
    func isEmpty_year_allZero_returnsTrue() {

        // Arrange
        let yearList: [PointOfYear] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 0),
                totalAchievementCount: 0,
                elements: []
            )
        ]
        let analytics = ContributionAnalytics(
            weekPointList: [],
            monthPointList: [],
            yearPointList: yearList,
            displayPeriod: .init(type: .year, anchor: Date.previewDate(year: 2026, month: 4, day: 30))
        )

        // Act & Assert
        #expect(analytics.isEmpty == true)
    }

    @Test("年表示でいずれかのメンバーが家事を達成していればisEmptyはfalse")
    func isEmpty_year_someAchieved_returnsFalse() {

        // Arrange
        let yearList: [PointOfYear] = [
            .init(
                userId: "u1",
                userName: "ユーザー1",
                total: .init(value: 100),
                totalAchievementCount: 5,
                elements: []
            )
        ]
        let analytics = ContributionAnalytics(
            weekPointList: [],
            monthPointList: [],
            yearPointList: yearList,
            displayPeriod: .init(type: .year, anchor: Date.previewDate(year: 2026, month: 4, day: 30))
        )

        // Act & Assert
        #expect(analytics.isEmpty == false)
    }

    @Test("メンバーがいない（pointListが空）ならisEmptyはtrue")
    func isEmpty_noMembers_returnsTrue() {

        // Arrange
        let analytics = ContributionAnalytics(
            weekPointList: [],
            monthPointList: [],
            yearPointList: [],
            displayPeriod: .init(type: .month, anchor: Date.previewDate(year: 2026, month: 4, day: 30))
        )

        // Act & Assert
        #expect(analytics.isEmpty == true)
    }
}
