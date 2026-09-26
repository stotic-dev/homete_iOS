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
        "選択中の種類の値だけで繰り返し方を返し、毎日は全曜日の毎週にし、くり返さない場合はnilを返す",
        arguments: [
            (kind: HouseworkRecurrenceInput.Kind.none, expected: HouseworkRecurrence?.none),
            (
                kind: .daily,
                expected: .some(.weekly([.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]))
            ),
            (kind: .weekly, expected: .some(.weekly([.tuesday]))),
            (kind: .monthly, expected: .some(.monthly(.dayOfMonth(25)))),
        ]
    )
    func recurrence(kind: HouseworkRecurrenceInput.Kind, expected: HouseworkRecurrence?) {
        // Arrange
        let input = HouseworkRecurrenceInput(
            kind: kind,
            weekdays: [.tuesday],
            dayOfMonth: 25
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
        "既存の繰り返し方から、その種類と値を選んだ入力状態を作る（全曜日の毎週は毎日にする）",
        arguments: [
            (
                recurrence: HouseworkRecurrence.weekly([.monday, .friday]),
                expected: HouseworkRecurrenceInput(kind: .weekly, weekdays: [.monday, .friday])
            ),
            (
                recurrence: .weekly([.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]),
                expected: HouseworkRecurrenceInput(
                    kind: .daily,
                    weekdays: [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
                )
            ),
            (
                recurrence: .monthly(.dayOfMonth(31)),
                expected: HouseworkRecurrenceInput(kind: .monthly, dayOfMonth: 31)
            ),
        ]
    )
    func initWithRecurrence(recurrence: HouseworkRecurrence, expected: HouseworkRecurrenceInput) {
        // Act
        let actual = HouseworkRecurrenceInput(recurrence: recurrence)

        // Assert
        #expect(actual == expected)
    }

    /// 2026/1/14は水曜日、2026/1/31は土曜日
    @Test(
        "基準日から、その日の曜日・日付を各種類の初期値にする",
        arguments: [
            (day: 14, expected: HouseworkRecurrenceInput(kind: .none, weekdays: [.wednesday], dayOfMonth: 14)),
            (day: 31, expected: HouseworkRecurrenceInput(kind: .none, weekdays: [.saturday], dayOfMonth: 31)),
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
            (rule: MonthlyRecurrenceRule.dayOfMonth(1), expected: "毎月1日"),
            (rule: .dayOfMonth(25), expected: "毎月25日"),
        ]
    )
    func label(rule: MonthlyRecurrenceRule, expected: String) {
        // Act
        let actual = rule.label

        // Assert
        #expect(actual == expected)
    }

}
