//
//  HouseworkRecurrenceInputTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import Foundation
@testable import HometeDomain
import Testing

enum HouseworkRecurrenceInputTest {

    struct RecurrenceCase {}
    struct InitCase {}
    struct LabelCase {}

}

extension HouseworkRecurrenceInputTest.RecurrenceCase {

    @Test(
        "選択中の種類の値だけで繰り返し方を返し、くり返さない場合と曜日未選択の場合はnilを返す",
        arguments: [
            (kind: HouseworkRecurrenceInput.Kind.none, expected: HouseworkRecurrence?.none),
            (kind: .weekly, expected: .some(.weekly([.tuesday]))),
            (kind: .monthlyDay, expected: .some(.monthly(.dayOfMonth(25)))),
            (kind: .monthlyWeekday, expected: .some(.monthly(.weekdayOfMonth(ordinal: .last, dayOfWeek: .friday)))),
        ]
    )
    func recurrence(kind: HouseworkRecurrenceInput.Kind, expected: HouseworkRecurrence?) {
        // Arrange
        let input = HouseworkRecurrenceInput(
            kind: kind,
            weekdays: [.tuesday],
            dayOfMonth: 25,
            ordinal: .last,
            monthlyDayOfWeek: .friday
        )

        // Act
        let actual = input.recurrence

        // Assert
        #expect(actual == expected)
    }

    @Test("毎週で曜日が1つも選ばれていない場合はnilを返す")
    func weeklyWithoutWeekdaysReturnsNil() {
        // Arrange
        let input = HouseworkRecurrenceInput(kind: .weekly, weekdays: [])

        // Act
        let actual = input.recurrence

        // Assert
        #expect(actual == nil)
    }

    @Test("毎週で曜日が1つも選ばれていない場合は入力未完了とみなす")
    func weeklyWithoutWeekdaysIsInvalid() {
        // Arrange
        let input = HouseworkRecurrenceInput(kind: .weekly, weekdays: [])

        // Act
        let actual = input.isValid

        // Assert
        #expect(actual == false)
    }

    @Test("くり返さない場合は入力完了とみなす")
    func noneIsValid() {
        // Arrange
        let input = HouseworkRecurrenceInput(kind: .none)

        // Act
        let actual = input.isValid

        // Assert
        #expect(actual == true)
    }

}

extension HouseworkRecurrenceInputTest.InitCase {

    @Test(
        "既存の繰り返し方から、その種類と値を選んだ入力状態を作る",
        arguments: [
            (
                recurrence: HouseworkRecurrence.weekly([.monday, .friday]),
                expected: HouseworkRecurrenceInput(kind: .weekly, weekdays: [.monday, .friday])
            ),
            (
                recurrence: .monthly(.dayOfMonth(31)),
                expected: HouseworkRecurrenceInput(kind: .monthlyDay, dayOfMonth: 31)
            ),
            (
                recurrence: .monthly(.weekdayOfMonth(ordinal: .third, dayOfWeek: .sunday)),
                expected: HouseworkRecurrenceInput(kind: .monthlyWeekday, ordinal: .third, monthlyDayOfWeek: .sunday)
            ),
        ]
    )
    func initWithRecurrence(recurrence: HouseworkRecurrence, expected: HouseworkRecurrenceInput) {
        // Act
        let actual = HouseworkRecurrenceInput(recurrence: recurrence)

        // Assert
        #expect(actual == expected)
    }

    /// 2026/1/14は第2水曜日、2026/1/29は第5木曜日
    @Test(
        "基準日から、その日の曜日・日付・第N週を各種類の初期値にする（第5週は最終にする）",
        arguments: [
            (
                day: 14,
                expected: HouseworkRecurrenceInput(
                    kind: .none,
                    weekdays: [.wednesday],
                    dayOfMonth: 14,
                    ordinal: .second,
                    monthlyDayOfWeek: .wednesday
                )
            ),
            (
                day: 29,
                expected: HouseworkRecurrenceInput(
                    kind: .none,
                    weekdays: [.thursday],
                    dayOfMonth: 29,
                    ordinal: .last,
                    monthlyDayOfWeek: .thursday
                )
            ),
        ]
    )
    func initBasedOnDate(day: Int, expected: HouseworkRecurrenceInput) {
        // Act
        let actual = HouseworkRecurrenceInput(
            kind: .none,
            basedOn: .previewDate(year: 2026, month: 1, day: day),
            calendar: .japanese
        )

        // Assert
        #expect(actual == expected)
    }

}

extension HouseworkRecurrenceInputTest.LabelCase {

    @Test(
        "毎月の繰り返しルールを表示用の文言にする",
        arguments: [
            (rule: MonthlyRecurrenceRule.dayOfMonth(25), expected: "毎月25日"),
            (rule: .weekdayOfMonth(ordinal: .second, dayOfWeek: .wednesday), expected: "毎月第2水曜日"),
            (rule: .weekdayOfMonth(ordinal: .last, dayOfWeek: .friday), expected: "毎月最終金曜日"),
        ]
    )
    func label(rule: MonthlyRecurrenceRule, expected: String) {
        // Act
        let actual = rule.label

        // Assert
        #expect(actual == expected)
    }

}
