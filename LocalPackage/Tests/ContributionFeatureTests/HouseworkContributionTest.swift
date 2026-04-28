//
//  HouseworkContributionTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import Testing
import HometeDomain
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct HouseworkContributionTest {
    struct MakeCase {
        private let calendar = Calendar.japanese
    }
    struct CalculatePointSummariesCase {
        private let calendar = Calendar.japanese
    }
}

extension HouseworkContributionTest.MakeCase {

    @Test("完了した家事のみ獲得ポイントとして集計される")
    func make_onlyCompletedItemsAreIncluded() {

        // Arrange
        let inputFirstDate = Date.previewDate(year: 2026, month: 1, day: 1)
        let inputSecondDate = Date.previewDate(year: 2026, month: 1, day: 2)
        let inputThirdDate = Date.previewDate(year: 2026, month: 1, day: 3)
        let items: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: inputFirstDate, point: 30, state: .completed, executorId: "alice"),
            .makeForTest(id: 2, indexedDate: inputSecondDate, point: 50, state: .incomplete, executorId: "alice"),
            .makeForTest(id: 3, indexedDate: inputThirdDate, point: 20, state: .completed, executorId: "alice")
        ]

        // Act
        let result = HouseworkContribution.make(by: items, calendar: calendar)

        // Assert
        let expectedList: [String: [PointOfDay]] = [
            "alice": [
                .init(indexedDay: inputFirstDate, point: .init(value: 30)),
                .init(indexedDay: inputThirdDate, point: .init(value: 20))
            ]
        ]
        #expect(result == .init(list: expectedList))
    }

    @Test("家事が空の場合は空のリストが返る")
    func make_emptyInput_returnsEmptyList() {

        // Arrange
        let items: [HouseworkItem] = []

        // Act
        let result = HouseworkContribution.make(by: items, calendar: calendar)

        // Assert
        #expect(result == .init(list: [:]))
    }
}

extension HouseworkContributionTest.CalculatePointSummariesCase {

    @Test("対象月の完了家事のポイントがユーザー毎に集計される")
    func calculatePointSummaries_returnsMonthlyPointPerUser() {

        // Arrange
        let jan10 = Date.previewDate(year: 2026, month: 1, day: 10)
        let jan20 = Date.previewDate(year: 2026, month: 1, day: 20)
        let items: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: jan10, point: 30, state: .completed, executorId: "alice"),
            .makeForTest(id: 2, indexedDate: jan20, point: 50, state: .completed, executorId: "bob")
        ]
        let contribution = HouseworkContribution.make(by: items, calendar: calendar)

        // Act
        let result = contribution.calculatePointSummaries(
            allUserIds: ["alice", "bob"],
            month: jan10,
            calendar: calendar
        )

        // Assert
        #expect(result == [
            PointSummary(userId: "alice", monthlyPoint: 30, thanksCount: 1),
            PointSummary(userId: "bob", monthlyPoint: 50, thanksCount: 1)
        ])
    }

    @Test("対象月外の家事は集計から除外される")
    func calculatePointSummaries_excludesItemsOutsideTargetMonth() {

        // Arrange
        let jan10 = Date.previewDate(year: 2026, month: 1, day: 10)
        let feb10 = Date.previewDate(year: 2026, month: 2, day: 10)
        let items: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: jan10, point: 30, state: .completed, executorId: "alice"),
            .makeForTest(id: 2, indexedDate: feb10, point: 50, state: .completed, executorId: "alice")
        ]
        let contribution = HouseworkContribution.make(by: items, calendar: calendar)

        // Act
        let result = contribution.calculatePointSummaries(allUserIds: ["alice"], month: jan10, calendar: calendar)

        // Assert
        #expect(result == [PointSummary(userId: "alice", monthlyPoint: 30, thanksCount: 1)])
    }

    @Test("レビュー済み家事の数がthanksCountに反映される")
    func calculatePointSummaries_includesThanksCount() {

        // Arrange
        let jan10 = Date.previewDate(year: 2026, month: 1, day: 10)
        let items: [HouseworkItem] = [
            .makeForTest(
                id: 1,
                indexedDate: jan10,
                point: 30,
                state: .completed,
                executorId: "alice",
                reviewerId: "bob"
            ),
            .makeForTest(
                id: 2,
                indexedDate: jan10,
                point: 20,
                state: .completed,
                executorId: "alice"
            ),
            .makeForTest(
                id: 3,
                indexedDate: jan10,
                point: 40,
                state: .completed,
                executorId: "alice",
                reviewerId: "bob"
            )
        ]
        let contribution = HouseworkContribution.make(by: items, calendar: calendar)

        // Act
        let result = contribution.calculatePointSummaries(allUserIds: ["alice"], month: jan10, calendar: calendar)

        // Assert
        #expect(result == [PointSummary(userId: "alice", monthlyPoint: 90, thanksCount: 3)])
    }

    @Test("対象月外のレビュー済み家事はthanksCountに含まれない")
    func calculatePointSummaries_excludesThanksItemsOutsideTargetMonth() {

        // Arrange
        let jan10 = Date.previewDate(year: 2026, month: 1, day: 10)
        let feb10 = Date.previewDate(year: 2026, month: 2, day: 10)
        let items: [HouseworkItem] = [
            .makeForTest(
                id: 1,
                indexedDate: jan10,
                point: 30,
                state: .completed,
                executorId: "alice",
                reviewerId: "bob"
            ),
            .makeForTest(
                id: 2,
                indexedDate: feb10,
                point: 50,
                state: .completed,
                executorId: "alice",
                reviewerId: "bob"
            )
        ]
        let contribution = HouseworkContribution.make(by: items, calendar: calendar)

        // Act
        let result = contribution.calculatePointSummaries(allUserIds: ["alice"], month: jan10, calendar: calendar)

        // Assert
        #expect(result == [PointSummary(userId: "alice", monthlyPoint: 30, thanksCount: 1)])
    }

    @Test("対象ユーザーに家事が存在しない場合はゼロのPointSummaryが返る")
    func calculatePointSummaries_noItemsForUser_returnsZeroSummary() {

        // Arrange
        let jan10 = Date.previewDate(year: 2026, month: 1, day: 10)
        let contribution = HouseworkContribution.make(by: [], calendar: calendar)

        // Act
        let result = contribution.calculatePointSummaries(allUserIds: ["alice"], month: jan10, calendar: calendar)

        // Assert
        #expect(result == [PointSummary(userId: "alice", monthlyPoint: 0, thanksCount: 0)])
    }
}
