//
//  MonthlyRecurrenceRuleTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import Foundation
@testable import HometeDomain
import Testing

enum MonthlyRecurrenceRuleTest {

    struct DayOfMonthCase {}
    struct WeekdayOfMonthCase {}
    struct CodableCase {}

}

extension MonthlyRecurrenceRuleTest.DayOfMonthCase {

    @Test(
        "毎月◯日は、その日付に一致する日だけ当てはまり、その日がない月は月末に当てはまる",
        arguments: [
            (day: 25, date: Date.previewDate(year: 2026, month: 1, day: 25), expected: true),
            (day: 25, date: Date.previewDate(year: 2026, month: 1, day: 24), expected: false),
            (day: 31, date: Date.previewDate(year: 2026, month: 3, day: 31), expected: true),
            (day: 31, date: Date.previewDate(year: 2026, month: 3, day: 30), expected: false),
            (day: 31, date: Date.previewDate(year: 2026, month: 2, day: 28), expected: true),
            (day: 31, date: Date.previewDate(year: 2026, month: 2, day: 27), expected: false),
            (day: 31, date: Date.previewDate(year: 2026, month: 4, day: 30), expected: true),
            (day: 30, date: Date.previewDate(year: 2028, month: 2, day: 29), expected: true),
            (day: 29, date: Date.previewDate(year: 2028, month: 2, day: 28), expected: false),
        ]
    )
    func matches(day: Int, date: Date, expected: Bool) {
        // Arrange

        let rule = MonthlyRecurrenceRule.dayOfMonth(day)

        // Act

        let actual = rule.matches(date, calendar: .japanese)

        // Assert

        #expect(actual == expected)
    }

}

extension MonthlyRecurrenceRuleTest.WeekdayOfMonthCase {

    /// 2026年1月は1日が木曜日で、水曜日は7・14・21・28日、木曜日は1・8・15・22・29日
    @Test(
        "毎月第N◯曜日は、その月の第N週の指定曜日だけ当てはまり、最終は月の最後の指定曜日に当てはまる",
        arguments: [
            (ordinal: WeekOrdinal.first, dayOfWeek: DayOfWeek.thursday, day: 1, expected: true),
            (ordinal: WeekOrdinal.second, dayOfWeek: DayOfWeek.wednesday, day: 14, expected: true),
            (ordinal: WeekOrdinal.second, dayOfWeek: DayOfWeek.wednesday, day: 7, expected: false),
            (ordinal: WeekOrdinal.second, dayOfWeek: DayOfWeek.thursday, day: 14, expected: false),
            (ordinal: WeekOrdinal.fourth, dayOfWeek: DayOfWeek.thursday, day: 22, expected: true),
            (ordinal: WeekOrdinal.fourth, dayOfWeek: DayOfWeek.thursday, day: 29, expected: false),
            (ordinal: WeekOrdinal.last, dayOfWeek: DayOfWeek.thursday, day: 29, expected: true),
            (ordinal: WeekOrdinal.last, dayOfWeek: DayOfWeek.wednesday, day: 28, expected: true),
            (ordinal: WeekOrdinal.last, dayOfWeek: DayOfWeek.wednesday, day: 21, expected: false),
        ]
    )
    func matches(ordinal: WeekOrdinal, dayOfWeek: DayOfWeek, day: Int, expected: Bool) {
        // Arrange

        let rule = MonthlyRecurrenceRule.weekdayOfMonth(ordinal: ordinal, dayOfWeek: dayOfWeek)
        let date = Date.previewDate(year: 2026, month: 1, day: day)

        // Act

        let actual = rule.matches(date, calendar: .japanese)

        // Assert

        #expect(actual == expected)
    }

}

extension MonthlyRecurrenceRuleTest.CodableCase {

    @Test(
        "Firestoreに保存する形のJSONから毎月の家事をデコードできる",
        arguments: [
            (
                json: #"{"id":"item","title":"家賃の振込","point":5,"updatedAt":0,"rule":{"type":"dayOfMonth","day":25}}"#,
                expectedRule: MonthlyRecurrenceRule.dayOfMonth(25)
            ),
            (
                json: #"""
                {"id":"item","title":"家賃の振込","point":5,"updatedAt":0,
                "rule":{"type":"weekdayOfMonth","ordinal":-1,"dayOfWeek":3}}
                """#,
                expectedRule: MonthlyRecurrenceRule.weekdayOfMonth(ordinal: .last, dayOfWeek: .wednesday)
            ),
        ]
    )
    func decode(json: String, expectedRule: MonthlyRecurrenceRule) throws {
        // Arrange

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let expected = HouseworkTemplateMonthlyItem(
            item: .init(id: .init(id: "item"), title: "家賃の振込", point: 5, updatedAt: Date(timeIntervalSince1970: 0)),
            rule: expectedRule
        )

        // Act

        let actual = try decoder.decode(HouseworkTemplateMonthlyItem.self, from: Data(json.utf8))

        // Assert

        #expect(actual == expected)
    }

    @Test("エンコードした毎月の家事をデコードすると元に戻る")
    func roundTrip() throws {
        // Arrange

        let expected = HouseworkTemplateMonthlyItem(
            item: .init(id: .init(id: "item"), title: "資源ゴミ", point: 3, updatedAt: Date(timeIntervalSince1970: 100)),
            rule: .weekdayOfMonth(ordinal: .second, dayOfWeek: .wednesday)
        )

        // Act

        let actual = try JSONDecoder().decode(
            HouseworkTemplateMonthlyItem.self,
            from: JSONEncoder().encode(expected)
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("未知の種類のルールはデコードに失敗する")
    func decodeUnknownRuleType() {
        // Arrange

        let json = #"{"type":"everyOtherWeek","dayOfWeek":1}"#

        // Act + Assert

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(MonthlyRecurrenceRule.self, from: Data(json.utf8))
        }
    }

}
