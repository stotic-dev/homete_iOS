//
//  TodayHouseworkSummaryTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2026/05/18.
//

// swiftlint:disable file_length

import Foundation
import HometeDomain
@testable import HouseworkFeature
import Testing

enum TodayHouseworkSummaryTest {

    static let today = Date.previewDate(year: 2026, month: 5, day: 18)
    static let calendar = Calendar.japanese

    struct EmptyCase {}
    struct AllCompletedCase {}
    struct HasIncompleteCase {}
    struct ProgressCase {}
    struct DisplayIncompleteItemsCase {}
    struct DateFilterCase {}
    struct TemplateCase {}

    static func makeStoredForToday(items: [HouseworkItem]) -> StoredAllHouseworkList {
        StoredAllHouseworkList(value: [
            DailyHouseworkList(
                items: items,
                metaData: DailyHouseworkMetaData(
                    indexedDate: .init(value: today),
                    expiredAt: .distantFuture
                )
            ),
        ])
    }

    /// テンプレートから生成される家事に設定される有効期限（当日の1年後）
    static func expiredAtOfToday() throws -> Date {
        try #require(calendar.date(byAdding: .year, value: 1, to: today))
    }

}

extension TodayHouseworkSummaryTest.EmptyCase {

    @Test("当日の家事が0件の場合、displayStateは.empty・progressは0・未完了リストも空になる")
    func empty_whenNoItems() {
        // Arrange

        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

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
        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [item1, item2, item3])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

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
        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [incomplete, completed])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [incomplete, completed],
            incompleteItems: [.init(originalItem: incomplete, isRegistered: true)],
            progress: 0.5,
            displayState: .hasIncomplete,
            displayIncompleteItems: [.init(originalItem: incomplete, isRegistered: true)],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

    @Test("pendingApprovalのみの場合でもdisplayStateは.hasIncompleteになり未完了として集計される")
    func hasIncomplete_whenOnlyPendingApprovalExists() {
        // Arrange

        let pendingApproval = HouseworkItem.makeForTest(id: 1, state: .pendingApproval)
        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [pendingApproval])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [pendingApproval],
            incompleteItems: [.init(originalItem: pendingApproval, isRegistered: true)],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [.init(originalItem: pendingApproval, isRegistered: true)],
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
        let input = TodayHouseworkSummaryTest.makeStoredForToday(
            items: [incomplete, pendingApproval, completed]
        )

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [incomplete, pendingApproval, completed],
            incompleteItems: [
                .init(originalItem: incomplete, isRegistered: true),
                .init(originalItem: pendingApproval, isRegistered: true),
            ],
            progress: 1.0 / 3.0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [
                .init(originalItem: incomplete, isRegistered: true),
                .init(originalItem: pendingApproval, isRegistered: true),
            ],
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
        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [item1, item2, item3, item4])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [item1, item2, item3, item4],
            incompleteItems: [
                .init(originalItem: item3, isRegistered: true),
                .init(originalItem: item4, isRegistered: true),
            ],
            progress: 0.5,
            displayState: .hasIncomplete,
            displayIncompleteItems: [
                .init(originalItem: item3, isRegistered: true),
                .init(originalItem: item4, isRegistered: true),
            ],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

    @Test("pendingApprovalは未完了として進捗率に含まれない（1/2 = 0.5）")
    func progress_pendingApprovalIsCountedAsIncomplete() {
        // Arrange

        let completed = HouseworkItem.makeForTest(id: 1, state: .completed)
        let pendingApproval = HouseworkItem.makeForTest(id: 2, state: .pendingApproval)
        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [completed, pendingApproval])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [completed, pendingApproval],
            incompleteItems: [.init(originalItem: pendingApproval, isRegistered: true)],
            progress: 0.5,
            displayState: .hasIncomplete,
            displayIncompleteItems: [.init(originalItem: pendingApproval, isRegistered: true)],
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
        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [item1, item2, item3, item4])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [item1, item2, item3, item4],
            incompleteItems: [
                .init(originalItem: item1, isRegistered: true),
                .init(originalItem: item2, isRegistered: true),
                .init(originalItem: item3, isRegistered: true),
                .init(originalItem: item4, isRegistered: true),
            ],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [
                .init(originalItem: item1, isRegistered: true),
                .init(originalItem: item2, isRegistered: true),
                .init(originalItem: item3, isRegistered: true),
                .init(originalItem: item4, isRegistered: true),
            ],
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
        let input = TodayHouseworkSummaryTest.makeStoredForToday(
            items: [item1, item2, item3, item4, item5]
        )

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [item1, item2, item3, item4, item5],
            incompleteItems: [
                .init(originalItem: item1, isRegistered: true),
                .init(originalItem: item2, isRegistered: true),
                .init(originalItem: item3, isRegistered: true),
                .init(originalItem: item4, isRegistered: true),
                .init(originalItem: item5, isRegistered: true),
            ],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [
                .init(originalItem: item1, isRegistered: true),
                .init(originalItem: item2, isRegistered: true),
                .init(originalItem: item3, isRegistered: true),
                .init(originalItem: item4, isRegistered: true),
            ],
            hasMoreIncomplete: true
        )
        #expect(actual == expected)
    }

}

extension TodayHouseworkSummaryTest.DateFilterCase {

    @Test("storedAllItemsが空の場合、displayStateは.emptyになる")
    func make_whenStoredAllItemsIsEmpty() {
        // Arrange

        let input = StoredAllHouseworkList(value: [])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

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

    @Test("当日の日付エントリが含まれない場合、displayStateは.emptyになる")
    func make_whenStoredAllItemsHasNoTodayEntry() {
        // Arrange

        let otherDate = Date.previewDate(year: 2026, month: 5, day: 17)
        let otherDayItem = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let input = StoredAllHouseworkList(value: [
            DailyHouseworkList(
                items: [otherDayItem],
                metaData: DailyHouseworkMetaData(
                    indexedDate: .init(value: otherDate),
                    expiredAt: .distantFuture
                )
            ),
        ])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

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

    @Test("複数日エントリのうち当日のもののみがサマリーに反映される")
    func make_picksOnlyTodayEntryFromMultipleDates() {
        // Arrange

        let yesterday = Date.previewDate(year: 2026, month: 5, day: 17)
        let tomorrow = Date.previewDate(year: 2026, month: 5, day: 19)
        let yesterdayItem = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let todayItem = HouseworkItem.makeForTest(id: 2, state: .incomplete)
        let tomorrowItem = HouseworkItem.makeForTest(id: 3, state: .incomplete)
        let input = StoredAllHouseworkList(value: [
            DailyHouseworkList(
                items: [yesterdayItem],
                metaData: DailyHouseworkMetaData(
                    indexedDate: .init(value: yesterday),
                    expiredAt: .distantFuture
                )
            ),
            DailyHouseworkList(
                items: [todayItem],
                metaData: DailyHouseworkMetaData(
                    indexedDate: .init(value: TodayHouseworkSummaryTest.today),
                    expiredAt: .distantFuture
                )
            ),
            DailyHouseworkList(
                items: [tomorrowItem],
                metaData: DailyHouseworkMetaData(
                    indexedDate: .init(value: tomorrow),
                    expiredAt: .distantFuture
                )
            ),
        ])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [todayItem],
            incompleteItems: [.init(originalItem: todayItem, isRegistered: true)],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [.init(originalItem: todayItem, isRegistered: true)],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

    @Test("nowに時刻成分がある場合でも、startOfDayで正規化された日付エントリを参照する")
    func make_normalizesNowToStartOfDay() {
        // Arrange

        let nowWithTime = Date.previewDate(
            year: 2026,
            month: 5,
            day: 18,
            hour: 15,
            minute: 30,
            second: 45
        )
        let todayItem = HouseworkItem.makeForTest(id: 1, state: .incomplete)
        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [todayItem])

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: nil,
            now: nowWithTime,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [todayItem],
            incompleteItems: [.init(originalItem: todayItem, isRegistered: true)],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [.init(originalItem: todayItem, isRegistered: true)],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

}

extension TodayHouseworkSummaryTest.TemplateCase {

    @Test("未登録のテンプレート家事も当日の家事としてサマリーに反映される")
    func make_mergesUnregisteredTemplateItems() throws {
        // Arrange

        let registeredItem = HouseworkItem.makeForTest(id: 1, state: .completed)
        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [registeredItem])
        let template = HouseworkTemplateDay(
            dayOfWeek: .monday,
            items: [
                .init(
                    id: .init(id: "templateId1"),
                    title: "洗濯",
                    point: 10,
                    updatedAt: Date.previewDate(year: 2026, month: 5, day: 17)
                ),
            ]
        )

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: template,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let templateItem = try HouseworkItem.makeForTest(
            id: "template-templateId1",
            indexedDate: TodayHouseworkSummaryTest.today,
            title: "洗濯",
            point: 10,
            state: .incomplete,
            expiredAt: TodayHouseworkSummaryTest.expiredAtOfToday(),
            templateHouseworkItemId: .init(id: "templateId1")
        )
        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [registeredItem, templateItem],
            incompleteItems: [.init(originalItem: templateItem, isRegistered: false)],
            progress: 0.5,
            displayState: .hasIncomplete,
            displayIncompleteItems: [.init(originalItem: templateItem, isRegistered: false)],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

    @Test("登録済みのテンプレート家事はテンプレート由来の家事として重複追加されない")
    func make_doesNotDuplicateRegisteredTemplateItems() {
        // Arrange

        let registeredItem = HouseworkItem.makeForTest(
            id: 1,
            state: .incomplete,
            templateHouseworkItemId: .init(id: "templateId1")
        )
        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [registeredItem])
        let template = HouseworkTemplateDay(
            dayOfWeek: .monday,
            items: [
                .init(
                    id: .init(id: "templateId1"),
                    title: "洗濯",
                    point: 10,
                    updatedAt: Date.previewDate(year: 2026, month: 5, day: 17)
                ),
            ]
        )

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: template,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [registeredItem],
            incompleteItems: [.init(originalItem: registeredItem, isRegistered: true)],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [.init(originalItem: registeredItem, isRegistered: true)],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

    @Test("当日より後に更新されたテンプレート家事はサマリーに反映されない")
    func make_excludesTemplateItemUpdatedAfterToday() {
        // Arrange

        let input = TodayHouseworkSummaryTest.makeStoredForToday(items: [])
        let template = HouseworkTemplateDay(
            dayOfWeek: .monday,
            items: [
                .init(
                    id: .init(id: "templateId1"),
                    title: "洗濯",
                    point: 10,
                    updatedAt: Date.previewDate(year: 2026, month: 5, day: 19)
                ),
            ]
        )

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: template,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

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

    @Test("当日の登録済み家事が0件でも、テンプレート家事があればサマリーに反映される")
    func make_mergesTemplateItemsWhenNoStoredEntryForToday() throws {
        // Arrange

        let input = StoredAllHouseworkList(value: [])
        let template = HouseworkTemplateDay(
            dayOfWeek: .monday,
            items: [
                .init(
                    id: .init(id: "templateId1"),
                    title: "洗濯",
                    point: 10,
                    updatedAt: Date.previewDate(year: 2026, month: 5, day: 17)
                ),
            ]
        )

        // Act

        let actual = TodayHouseworkSummary.make(
            storedAllItems: input,
            template: template,
            now: TodayHouseworkSummaryTest.today,
            calendar: TodayHouseworkSummaryTest.calendar,
            storagePolicy: .free
        )

        // Assert

        let templateItem = try HouseworkItem.makeForTest(
            id: "template-templateId1",
            indexedDate: TodayHouseworkSummaryTest.today,
            title: "洗濯",
            point: 10,
            state: .incomplete,
            expiredAt: TodayHouseworkSummaryTest.expiredAtOfToday(),
            templateHouseworkItemId: .init(id: "templateId1")
        )
        let expected = TodayHouseworkSummary.makeForTest(
            allItems: [templateItem],
            incompleteItems: [.init(originalItem: templateItem, isRegistered: false)],
            progress: 0,
            displayState: .hasIncomplete,
            displayIncompleteItems: [.init(originalItem: templateItem, isRegistered: false)],
            hasMoreIncomplete: false
        )
        #expect(actual == expected)
    }

}
