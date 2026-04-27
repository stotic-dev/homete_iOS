//
//  PointSummaryTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import Testing
import HometeDomain
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct PointSummaryTest {
    struct CalculateCase {
        private let calendar = Calendar.japanese
    }
}

extension PointSummaryTest.CalculateCase {

    @Test("対象ユーザーが対象月に完了した家事のポイントが合算される")
    func calculate_monthlyPoint_sumsTargetUsersCompletedItemsInMonth() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))
        comps.day = 20
        let april20 = try #require(calendar.date(from: comps))

        let items: [HouseworkItem] = [
            .makeForTest(id: 1, point: 30, state: .completed, executorId: "alice", approvedAt: april10),
            .makeForTest(id: 2, point: 50, state: .completed, executorId: "alice", approvedAt: april20)
        ]

        // Act
        let result = PointSummary.calculate(userId: "alice", from: items, in: april10, calendar: calendar)

        // Assert
        #expect(result.monthlyPoint == 80)
    }

    @Test("他のユーザーが完了した家事は自分のポイントに含まれない")
    func calculate_monthlyPoint_excludesOtherUsersItems() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))

        let items: [HouseworkItem] = [
            .makeForTest(id: 1, point: 30, state: .completed, executorId: "alice", approvedAt: april10),
            .makeForTest(id: 2, point: 50, state: .completed, executorId: "bob", approvedAt: april10)
        ]

        // Act
        let result = PointSummary.calculate(userId: "alice", from: items, in: april10, calendar: calendar)

        // Assert
        #expect(result.monthlyPoint == 30)
    }

    @Test("対象月以外に完了した家事は集計から除外される")
    func calculate_monthlyPoint_excludesItemsOutsideTargetMonth() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))
        comps.month = 3
        let march10 = try #require(calendar.date(from: comps))

        let items: [HouseworkItem] = [
            .makeForTest(id: 1, point: 30, state: .completed, executorId: "alice", approvedAt: april10),
            .makeForTest(id: 2, point: 50, state: .completed, executorId: "alice", approvedAt: march10)
        ]

        // Act
        let result = PointSummary.calculate(userId: "alice", from: items, in: april10, calendar: calendar)

        // Assert
        #expect(result.monthlyPoint == 30)
    }

    @Test("未完了の家事はポイント集計から除外される")
    func calculate_monthlyPoint_excludesIncompleteItems() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))

        let items: [HouseworkItem] = [
            .makeForTest(id: 1, point: 30, state: .completed, executorId: "alice", approvedAt: april10),
            .makeForTest(id: 2, point: 50, state: .incomplete, executorId: "alice")
        ]

        // Act
        let result = PointSummary.calculate(userId: "alice", from: items, in: april10, calendar: calendar)

        // Assert
        #expect(result.monthlyPoint == 30)
    }

    @Test("レビュー済みの完了家事の数がthanksCountになる")
    func calculate_thanksCount_countsReviewedItemsByTargetUser() throws {

        // Arrange
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 10
        let april10 = try #require(calendar.date(from: comps))

        let items: [HouseworkItem] = [
            .makeForTest(id: 1, state: .completed, executorId: "alice", reviewerId: "bob", approvedAt: april10),
            .makeForTest(id: 2, state: .completed, executorId: "alice", reviewerId: nil, approvedAt: april10),
            .makeForTest(id: 3, state: .completed, executorId: "alice", reviewerId: "bob", approvedAt: april10)
        ]

        // Act
        let result = PointSummary.calculate(userId: "alice", from: items, in: april10, calendar: calendar)

        // Assert
        #expect(result.thanksCount == 2)
    }
}
