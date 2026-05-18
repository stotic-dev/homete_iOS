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

        let actual = TodayHouseworkSummary(allItems: input)

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [],
            incompleteItems: [],
            progress: 0,
            displayState: .empty,
            displayIncompleteItems: [],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

}

extension TodayHouseworkSummaryTest.AllCompletedCase {

    @Test("全ての家事が完了の場合、displayStateは.allCompleted・progressは1.0になる")
    func allCompleted_whenAllItemsCompleted() {
        // Arrange

        let item1 = HouseworkItem.makeForTest(id: 1, state: .completed)
        let item2 = HouseworkItem.makeForTest(id: 2, state: .completed)
        let item3 = HouseworkItem.makeForTest(id: 3, state: .completed)
        let input: [HouseworkItem] = [item1, item2, item3]

        // Act

        let actual = TodayHouseworkSummary(allItems: input)

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [item1, item2, item3],
            incompleteItems: [],
            progress: 1.0,
            displayState: .allCompleted,
            displayIncompleteItems: [],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

}

extension TodayHouseworkSummaryTest.HasIncompleteCase {

    @Test("incompleteのみの場合、displayStateは.hasIncompleteになり未完了として集計される")
    func hasIncomplete_whenIncompleteItemExists() {
        // Arrange

        let incomplete = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let completed = HouseworkItem.makeForTest(id: 2, state: .completed)
        let input: [HouseworkItem] = [incomplete, completed]

        // Act

        let actual = TodayHouseworkSummary(allItems: input)

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [incomplete, completed],
            incompleteItems: [incomplete],
            progress: 0.5,
            displayState: .hasIncomplete,
            displayIncompleteItems: [incomplete],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

    @Test("pendingApprovalのみの場合でもdisplayStateは.hasIncompleteになり未完了として集計される")
    func hasIncomplete_whenOnlyPendingApprovalExists() {
        // Arrange

        let pendingApproval = HouseworkItem.makeForTest(id: 1, state: .pendingApproval)
        let input: [HouseworkItem] = [pendingApproval]

        // Act

        let actual = TodayHouseworkSummary(allItems: input)

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [pendingApproval],
            incompleteItems: [pendingApproval],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [pendingApproval],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

    @Test("incompleteとpendingApprovalの両方を未完了として集計する")
    func incompleteItems_includeIncompleteAndPendingApproval() {
        // Arrange

        let incomplete = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let pendingApproval = HouseworkItem.makeForTest(id: 2, state: .pendingApproval)
        let completed = HouseworkItem.makeForTest(id: 3, state: .completed)
        let input: [HouseworkItem] = [incomplete, pendingApproval, completed]

        // Act

        let actual = TodayHouseworkSummary(allItems: input)

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [incomplete, pendingApproval, completed],
            incompleteItems: [incomplete, pendingApproval],
            progress: 1.0 / 3.0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [incomplete, pendingApproval],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

}

extension TodayHouseworkSummaryTest.ProgressCase {

    @Test("進捗率は 完了数 / 全数 で算出する（2/4 = 0.5）")
    func progress_twoOfFour() {
        // Arrange

        let item1 = HouseworkItem.makeForTest(id: 1, state: .completed)
        let item2 = HouseworkItem.makeForTest(id: 2, state: .completed)
        let item3 = HouseworkItem.makeForTest(id: 3, state: .incomplete)
        let item4 = HouseworkItem.makeForTest(id: 4, state: .incomplete)
        let input: [HouseworkItem] = [item1, item2, item3, item4]

        // Act

        let actual = TodayHouseworkSummary(allItems: input)

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [item1, item2, item3, item4],
            incompleteItems: [item3, item4],
            progress: 0.5,
            displayState: .hasIncomplete,
            displayIncompleteItems: [item3, item4],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

    @Test("pendingApprovalは未完了として進捗率に含まれない（1/2 = 0.5）")
    func progress_pendingApprovalIsCountedAsIncomplete() {
        // Arrange

        let completed = HouseworkItem.makeForTest(id: 1, state: .completed)
        let pendingApproval = HouseworkItem.makeForTest(id: 2, state: .pendingApproval)
        let input: [HouseworkItem] = [completed, pendingApproval]

        // Act

        let actual = TodayHouseworkSummary(allItems: input)

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [completed, pendingApproval],
            incompleteItems: [pendingApproval],
            progress: 0.5,
            displayState: .hasIncomplete,
            displayIncompleteItems: [pendingApproval],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

}

extension TodayHouseworkSummaryTest.DisplayIncompleteItemsCase {

    @Test("未完了が4件以下の場合はhasMoreIncompleteがfalseになり全件表示される")
    func hasMoreIncomplete_falseWhenIncompleteCountIsLessThanOrEqualToLimit() {
        // Arrange

        let item1 = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let item2 = HouseworkItem.makeForTest(id: 2, state: .incomplete)
        let item3 = HouseworkItem.makeForTest(id: 3, state: .incomplete)
        let item4 = HouseworkItem.makeForTest(id: 4, state: .incomplete)
        let input: [HouseworkItem] = [item1, item2, item3, item4]

        // Act

        let actual = TodayHouseworkSummary(allItems: input)

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [item1, item2, item3, item4],
            incompleteItems: [item1, item2, item3, item4],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [item1, item2, item3, item4],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

    @Test("未完了が5件以上の場合はhasMoreIncompleteがtrueになり先頭4件のみ表示される")
    func hasMoreIncomplete_trueWhenIncompleteCountExceedsLimit() {
        // Arrange

        let item1 = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let item2 = HouseworkItem.makeForTest(id: 2, state: .incomplete)
        let item3 = HouseworkItem.makeForTest(id: 3, state: .incomplete)
        let item4 = HouseworkItem.makeForTest(id: 4, state: .incomplete)
        let item5 = HouseworkItem.makeForTest(id: 5, state: .incomplete)
        let input: [HouseworkItem] = [item1, item2, item3, item4, item5]

        // Act

        let actual = TodayHouseworkSummary(allItems: input)

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [item1, item2, item3, item4, item5],
            incompleteItems: [item1, item2, item3, item4, item5],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [item1, item2, item3, item4],
            hasMoreIncomplete: true
        )
        #expect(actual == expected)
    }

}
