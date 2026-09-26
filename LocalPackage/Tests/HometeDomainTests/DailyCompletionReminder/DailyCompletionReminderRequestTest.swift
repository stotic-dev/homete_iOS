//
//  DailyCompletionReminderRequestTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct DailyCompletionReminderRequestTest {

    @Test("識別子は日付ごとに決まる")
    func identifier_returnsDayBasedIdentifier() {
        // Act

        let actual = DailyCompletionReminderRequest.identifier(
            for: .previewDate(year: 2026, month: 9, day: 5, hour: 23, minute: 59),
            calendar: .japanese
        )

        // Assert

        #expect(actual == "dailyCompletionReminder-2026-9-5")
    }

    @Test("通知が有効で指定時刻の前なら、その日の指定時刻に通知する")
    func make_enabledAndBeforeFireTime_returnsRequest() {
        // Arrange

        let expected = DailyCompletionReminderRequest(
            identifier: "dailyCompletionReminder-2026-9-25",
            fireDateComponents: DateComponents(year: 2026, month: 9, day: 25, hour: 21, minute: 30),
            title: "今日もおつかれさまでした",
            body: "今日完了した家事があります。ふりかえって、感謝を伝え合いましょう"
        )

        // Act

        let actual = DailyCompletionReminderRequest.make(
            day: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            setting: .init(isEnabled: true, hour: 21, minute: 30),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("通知が無効なら予約しない")
    func make_disabled_returnsNil() {
        // Act

        let actual = DailyCompletionReminderRequest.make(
            day: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            setting: .init(isEnabled: false, hour: 21, minute: 30),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese
        )

        // Assert

        #expect(actual == nil)
    }

    @Test(
        "指定時刻ちょうど、または過ぎていたら予約しない",
        arguments: [
            Date.previewDate(year: 2026, month: 9, day: 25, hour: 21, minute: 30),
            Date.previewDate(year: 2026, month: 9, day: 25, hour: 22),
        ]
    )
    func make_atOrAfterFireTime_returnsNil(now: Date) {
        // Act

        let actual = DailyCompletionReminderRequest.make(
            day: now,
            setting: .init(isEnabled: true, hour: 21, minute: 30),
            now: now,
            calendar: .japanese
        )

        // Assert

        #expect(actual == nil)
    }

    @Test("1日1回の制限を外している場合は、予約ごとに別の識別子にする")
    func make_allowsMultiplePerDay_returnsRequestWithPerScheduleIdentifier() {
        // Arrange

        let expected = DailyCompletionReminderRequest(
            identifier: "dailyCompletionReminder-2026-9-25#1790298000",
            fireDateComponents: DateComponents(year: 2026, month: 9, day: 25, hour: 21, minute: 30),
            title: "今日もおつかれさまでした",
            body: "今日完了した家事があります。ふりかえって、感謝を伝え合いましょう"
        )

        // Act

        let actual = DailyCompletionReminderRequest.make(
            day: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            setting: .init(isEnabled: true, hour: 21, minute: 30),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 10),
            calendar: .japanese,
            allowsMultiplePerDay: true
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("きっかけを指定した場合は、きっかけと予約した時刻を本文の末尾に載せる")
    func make_withDebugTrigger_appendsDebugNoteToBody() {
        // Arrange

        let expected = DailyCompletionReminderRequest(
            identifier: "dailyCompletionReminder-2026-9-25",
            fireDateComponents: DateComponents(year: 2026, month: 9, day: 25, hour: 21, minute: 30),
            title: "今日もおつかれさまでした",
            body: "今日完了した家事があります。ふりかえって、感謝を伝え合いましょう\n[DEBUG] 家事一覧 / 09:05予約"
        )

        // Act

        let actual = DailyCompletionReminderRequest.make(
            day: .previewDate(year: 2026, month: 9, day: 25, hour: 9, minute: 5),
            setting: .init(isEnabled: true, hour: 21, minute: 30),
            now: .previewDate(year: 2026, month: 9, day: 25, hour: 9, minute: 5),
            calendar: .japanese,
            debugTrigger: .houseworkList
        )

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "その日の識別子、または制限を外して予約したその日の識別子なら、その日の通知と判定する",
        arguments: [
            ("dailyCompletionReminder-2026-9-2", true),
            ("dailyCompletionReminder-2026-9-2#1790298000", true),
            ("dailyCompletionReminder-2026-9-25", false),
            ("dailyCompletionReminder-2026-9-25#1790298000", false),
        ]
    )
    func isIdentifier_returnsWhetherSameDay(requestIdentifier: String, expected: Bool) {
        // Act

        let actual = DailyCompletionReminderRequest.isIdentifier(
            requestIdentifier,
            ofDay: "dailyCompletionReminder-2026-9-2"
        )

        // Assert

        #expect(actual == expected)
    }

}
