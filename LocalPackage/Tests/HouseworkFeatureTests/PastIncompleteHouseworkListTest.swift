//
//  PastIncompleteHouseworkListTest.swift
//  hometeTests
//

import Foundation
import HometeDomain
@testable import HouseworkFeature
import Testing

enum PastIncompleteHouseworkListTest {

    static let today = Date.previewDate(year: 2026, month: 5, day: 18)
    static let yesterday = Date.previewDate(year: 2026, month: 5, day: 17)
    static let twoDaysAgo = Date.previewDate(year: 2026, month: 5, day: 16)
    static let calendar = Calendar.japanese

    struct MakeCase {}
    struct DatesCase {}
    struct ElementsCase {}

    static func makeDailyList(date: Date, items: [HouseworkItem]) -> DailyHouseworkList {
        DailyHouseworkList(
            items: items,
            metaData: DailyHouseworkMetaData(indexedDate: .init(value: date), expiredAt: .distantFuture)
        )
    }

    /// 指定した日付ごとに、未完了の家事を1件ずつ置いた区切り
    static func makeSections(dates: [Date]) -> [PastIncompleteHouseworkList.DaySection] {
        dates.enumerated().map { offset, date in
            .init(
                date: date,
                items: [.init(originalItem: .makeForTest(id: offset, indexedDate: date), isRegistered: true)]
            )
        }
    }

}

extension PastIncompleteHouseworkListTest.MakeCase {

    @Test("昨日以前の未完了の家事だけを、日付が新しい順に日ごとにまとめる")
    func make_groupsPastIncompleteByDateDescending() {
        // Arrange

        let today = PastIncompleteHouseworkListTest.today
        let yesterday = PastIncompleteHouseworkListTest.yesterday
        let twoDaysAgo = PastIncompleteHouseworkListTest.twoDaysAgo
        let olderItem = HouseworkItem.makeForTest(id: 1, indexedDate: twoDaysAgo)
        let yesterdayItem = HouseworkItem.makeForTest(id: 2, indexedDate: yesterday)
        let input = StoredAllHouseworkList(value: [
            PastIncompleteHouseworkListTest.makeDailyList(date: twoDaysAgo, items: [olderItem]),
            PastIncompleteHouseworkListTest.makeDailyList(
                date: today,
                items: [.makeForTest(id: 3, indexedDate: today)]
            ),
            PastIncompleteHouseworkListTest.makeDailyList(date: yesterday, items: [yesterdayItem]),
        ])

        // Act

        let actual = PastIncompleteHouseworkList.make(
            storedAllItems: input,
            now: Date.previewDate(year: 2026, month: 5, day: 18, hour: 12),
            calendar: PastIncompleteHouseworkListTest.calendar
        )

        // Assert

        let expected = PastIncompleteHouseworkList(sections: [
            .init(date: yesterday, items: [.init(originalItem: yesterdayItem, isRegistered: true)]),
            .init(date: twoDaysAgo, items: [.init(originalItem: olderItem, isRegistered: true)]),
        ])
        #expect(actual == expected)
    }

    @Test("完了・やらないにした家事は含めず、未完了が残らない日は区切りごと除く")
    func make_excludesFinishedItems() {
        // Arrange

        let yesterday = PastIncompleteHouseworkListTest.yesterday
        let twoDaysAgo = PastIncompleteHouseworkListTest.twoDaysAgo
        let incompleteItem = HouseworkItem.makeForTest(id: 1, indexedDate: yesterday)
        let input = StoredAllHouseworkList(value: [
            PastIncompleteHouseworkListTest.makeDailyList(
                date: yesterday,
                items: [
                    incompleteItem,
                    .makeForTest(id: 2, indexedDate: yesterday, state: .completed),
                ]
            ),
            PastIncompleteHouseworkListTest.makeDailyList(
                date: twoDaysAgo,
                items: [.makeForTest(id: 3, indexedDate: twoDaysAgo, state: .notTodo)]
            ),
        ])

        // Act

        let actual = PastIncompleteHouseworkList.make(
            storedAllItems: input,
            now: PastIncompleteHouseworkListTest.today,
            calendar: PastIncompleteHouseworkListTest.calendar
        )

        // Assert

        let expected = PastIncompleteHouseworkList(sections: [
            .init(date: yesterday, items: [.init(originalItem: incompleteItem, isRegistered: true)]),
        ])
        #expect(actual == expected)
    }

    @Test("同じ日の家事はポイントの高い順に並べる")
    func make_sortsItemsByPointDescending() {
        // Arrange

        let yesterday = PastIncompleteHouseworkListTest.yesterday
        let lowPointItem = HouseworkItem.makeForTest(id: 1, indexedDate: yesterday, point: 10)
        let highPointItem = HouseworkItem.makeForTest(id: 2, indexedDate: yesterday, point: 30)
        let input = StoredAllHouseworkList(value: [
            PastIncompleteHouseworkListTest.makeDailyList(date: yesterday, items: [lowPointItem, highPointItem]),
        ])

        // Act

        let actual = PastIncompleteHouseworkList.make(
            storedAllItems: input,
            now: PastIncompleteHouseworkListTest.today,
            calendar: PastIncompleteHouseworkListTest.calendar
        )

        // Assert

        let expected = PastIncompleteHouseworkList(sections: [
            .init(
                date: yesterday,
                items: [
                    .init(originalItem: highPointItem, isRegistered: true),
                    .init(originalItem: lowPointItem, isRegistered: true),
                ]
            ),
        ])
        #expect(actual == expected)
    }

    @Test("昨日以前の家事が無ければ空になる")
    func make_emptyWhenNoPastItems() {
        // Arrange

        let today = PastIncompleteHouseworkListTest.today
        let input = StoredAllHouseworkList(value: [
            PastIncompleteHouseworkListTest.makeDailyList(
                date: today,
                items: [.makeForTest(id: 1, indexedDate: today)]
            ),
        ])

        // Act

        let actual = PastIncompleteHouseworkList.make(
            storedAllItems: input,
            now: today,
            calendar: PastIncompleteHouseworkListTest.calendar
        )

        // Assert

        let expected = PastIncompleteHouseworkList(sections: [])
        #expect(actual == expected)
    }

}

extension PastIncompleteHouseworkListTest.DatesCase {

    @Test("未完了の家事がある日付を返す")
    func dates() {
        // Arrange

        let yesterday = PastIncompleteHouseworkListTest.yesterday
        let twoDaysAgo = PastIncompleteHouseworkListTest.twoDaysAgo
        let list = PastIncompleteHouseworkList(
            sections: PastIncompleteHouseworkListTest.makeSections(dates: [yesterday, twoDaysAgo])
        )

        // Act

        let actual = list.dates

        // Assert

        #expect(actual == [yesterday, twoDaysAgo])
    }

}

extension PastIncompleteHouseworkListTest.ElementsCase {

    @Test("広告を出す場合、日付の区切り3つごとに広告を挟み、末尾には付けない")
    func elements_insertsAdvertisementEveryThreeSections() {
        // Arrange

        let dates = (1 ... 7).map { Date.previewDate(year: 2026, month: 5, day: 18 - $0) }
        let sections = PastIncompleteHouseworkListTest.makeSections(dates: dates)
        let list = PastIncompleteHouseworkList(sections: sections)

        // Act

        let actual = list.elements(showsAdvertisement: true)

        // Assert

        let expected: [PastIncompleteHouseworkList.Element] = [
            .section(sections[0]),
            .section(sections[1]),
            .section(sections[2]),
            .advertisement(index: 0),
            .section(sections[3]),
            .section(sections[4]),
            .section(sections[5]),
            .advertisement(index: 1),
            .section(sections[6]),
        ]
        #expect(actual == expected)
    }

    @Test("区切りがちょうど3つのとき、末尾に広告を付けない")
    func elements_noTrailingAdvertisement() {
        // Arrange

        let dates = (1 ... 3).map { Date.previewDate(year: 2026, month: 5, day: 18 - $0) }
        let sections = PastIncompleteHouseworkListTest.makeSections(dates: dates)
        let list = PastIncompleteHouseworkList(sections: sections)

        // Act

        let actual = list.elements(showsAdvertisement: true)

        // Assert

        let expected: [PastIncompleteHouseworkList.Element] = [
            .section(sections[0]),
            .section(sections[1]),
            .section(sections[2]),
        ]
        #expect(actual == expected)
    }

    @Test("広告を出さない場合、日付の区切りだけを並べる")
    func elements_withoutAdvertisement() {
        // Arrange

        let dates = (1 ... 4).map { Date.previewDate(year: 2026, month: 5, day: 18 - $0) }
        let sections = PastIncompleteHouseworkListTest.makeSections(dates: dates)
        let list = PastIncompleteHouseworkList(sections: sections)

        // Act

        let actual = list.elements(showsAdvertisement: false)

        // Assert

        let expected: [PastIncompleteHouseworkList.Element] = sections.map { .section($0) }
        #expect(actual == expected)
    }

}
