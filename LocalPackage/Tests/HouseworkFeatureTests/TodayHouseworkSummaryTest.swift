//
//  TodayHouseworkSummaryTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import Foundation
import HometeDomain
@testable import HouseworkFeature
import Testing

enum TodayHouseworkSummaryTest {

    struct EmptyCase {}
    struct AllCompletedCase {}
    struct HasIncompleteCase {}
    struct ProgressCase {}
    struct DisplayIncompleteItemsCase {}

}

extension TodayHouseworkSummaryTest.EmptyCase {

    @Test("家事が0件の場合、displayStateは.empty・progressは0・未完了リストも空になる")
    func empty_whenNoItems() {
        // Arrange

        let input: [HouseworkItem] = []

        // Act

        let summary = TodayHouseworkSummary(allItems: input)

        // Assert

        #expect(summary.displayState == .empty)
        #expect(summary.progress == 0)
        #expect(summary.allItems.isEmpty)
        #expect(summary.incompleteItems.isEmpty)
        #expect(summary.displayIncompleteItems.isEmpty)
        #expect(summary.hasMoreIncomplete == false)
    }

}

extension TodayHouseworkSummaryTest.AllCompletedCase {

    @Test("全ての家事が完了の場合、displayStateは.allCompleted・progressは1.0になる")
    func allCompleted_whenAllItemsCompleted() {
        // Arrange

        let input: [HouseworkItem] = [
            .makeForTest(id: 1, state: .completed),
            .makeForTest(id: 2, state: .completed),
            .makeForTest(id: 3, state: .completed),
        ]

        // Act

        let summary = TodayHouseworkSummary(allItems: input)

        // Assert

        #expect(summary.displayState == .allCompleted)
        #expect(summary.progress == 1.0)
        #expect(summary.incompleteItems.isEmpty)
        #expect(summary.displayIncompleteItems.isEmpty)
        #expect(summary.hasMoreIncomplete == false)
    }

}

extension TodayHouseworkSummaryTest.HasIncompleteCase {

    @Test("未完了の家事がある場合、displayStateは.hasIncompleteになる")
    func hasIncomplete_whenIncompleteItemExists() {
        // Arrange

        let input: [HouseworkItem] = [
            .makeForTest(id: 1, state: .incomplete),
            .makeForTest(id: 2, state: .completed),
        ]

        // Act

        let summary = TodayHouseworkSummary(allItems: input)

        // Assert

        #expect(summary.displayState == .hasIncomplete)
    }

    @Test("pendingApprovalのみの場合でもdisplayStateは.hasIncompleteになる")
    func hasIncomplete_whenOnlyPendingApprovalExists() {
        // Arrange

        let input: [HouseworkItem] = [
            .makeForTest(id: 1, state: .pendingApproval),
        ]

        // Act

        let summary = TodayHouseworkSummary(allItems: input)

        // Assert

        #expect(summary.displayState == .hasIncomplete)
    }

    @Test("incompleteとpendingApprovalの両方を未完了として集計する")
    func incompleteItems_includeIncompleteAndPendingApproval() {
        // Arrange

        let incomplete = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let pendingApproval = HouseworkItem.makeForTest(id: 2, state: .pendingApproval)
        let completed = HouseworkItem.makeForTest(id: 3, state: .completed)
        let input: [HouseworkItem] = [incomplete, pendingApproval, completed]

        // Act

        let summary = TodayHouseworkSummary(allItems: input)

        // Assert

        #expect(summary.incompleteItems == [incomplete, pendingApproval])
    }

}

extension TodayHouseworkSummaryTest.ProgressCase {

    @Test(
        "進捗率は 完了数 / 全数 で算出する",
        arguments: [
            (states: [HouseworkState.completed, .completed, .incomplete, .incomplete], expected: 0.5),
            (states: [HouseworkState.completed, .incomplete, .incomplete, .incomplete], expected: 0.25),
            (states: [HouseworkState.completed, .pendingApproval], expected: 0.5),
            (states: [HouseworkState.incomplete, .pendingApproval], expected: 0.0),
        ]
    )
    func progress_iscompletedCountDividedByAllCount(states: [HouseworkState], expected: Double) {
        // Arrange

        let input: [HouseworkItem] = states.enumerated().map { index, state in
            .makeForTest(id: index + 1, state: state)
        }

        // Act

        let summary = TodayHouseworkSummary(allItems: input)

        // Assert

        #expect(summary.progress == expected)
    }

}

extension TodayHouseworkSummaryTest.DisplayIncompleteItemsCase {

    @Test("未完了が4件以下の場合はhasMoreIncompleteがfalseになり全件表示される")
    func hasMoreIncomplete_falseWhenIncompleteCountIsLessThanOrEqualToLimit() {
        // Arrange

        let incompleteItems: [HouseworkItem] = (1 ... 4).map {
            .makeForTest(id: $0, state: .incomplete)
        }

        // Act

        let summary = TodayHouseworkSummary(allItems: incompleteItems)

        // Assert

        #expect(summary.displayIncompleteItems == incompleteItems)
        #expect(summary.hasMoreIncomplete == false)
    }

    @Test("未完了が5件以上の場合はhasMoreIncompleteがtrueになり先頭4件のみ表示される")
    func hasMoreIncomplete_trueWhenIncompleteCountExceedsLimit() {
        // Arrange

        let incompleteItems: [HouseworkItem] = (1 ... 5).map {
            .makeForTest(id: $0, state: .incomplete)
        }

        // Act

        let summary = TodayHouseworkSummary(allItems: incompleteItems)

        // Assert

        #expect(summary.displayIncompleteItems == Array(incompleteItems.prefix(4)))
        #expect(summary.hasMoreIncomplete == true)
    }

}
