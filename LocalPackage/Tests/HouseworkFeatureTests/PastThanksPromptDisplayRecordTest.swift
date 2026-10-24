//
//  PastThanksPromptDisplayRecordTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct PastThanksPromptDisplayRecordTest {

    private let calendar = Calendar.japanese
    private let now = Date.previewDate(year: 2026, month: 10, day: 6, hour: 8)
    private let today = Date.previewDate(year: 2026, month: 10, day: 6, hour: 0)

    // MARK: reconciled

    @Test("まだ記録していなければ、今日の記録として数え始める")
    func reconciled_noRecord_startsToday() {
        // Arrange
        let record = PastThanksPromptDisplayRecord()

        // Act
        let actual = record.reconciled(now: now, calendar: calendar)

        // Assert
        #expect(actual == .init(day: today))
    }

    @Test("日付が変わったら、表示回数を戻す")
    func reconciled_dayChanged_resetsRecord() {
        // Arrange
        let record = PastThanksPromptDisplayRecord(
            day: .previewDate(year: 2026, month: 10, day: 5, hour: 0),
            shownCount: 2
        )

        // Act
        let actual = record.reconciled(now: now, calendar: calendar)

        // Assert
        #expect(actual == .init(day: today))
    }

    @Test("同じ日なら、表示回数をそのまま使う")
    func reconciled_sameDay_keepsRecord() {
        // Arrange
        let record = PastThanksPromptDisplayRecord(day: today, shownCount: 1)

        // Act
        let actual = record.reconciled(now: now, calendar: calendar)

        // Assert
        #expect(actual == .init(day: today, shownCount: 1))
    }

    // MARK: canShow

    @Test(
        "1日2回までは出し、上限に達しても数えた表示の間は出し続ける",
        arguments: [
            (1, false, true),
            (2, false, false),
            (2, true, true),
        ]
    )
    func canShow(shownCount: Int, isCountedInCurrentAppearance: Bool, expected: Bool) {
        // Arrange
        let record = PastThanksPromptDisplayRecord(day: today, shownCount: shownCount)

        // Act
        let actual = record.canShow(isCountedInCurrentAppearance: isCountedInCurrentAppearance)

        // Assert
        #expect(actual == expected)
    }

    // MARK: recordShown

    @Test("出したら、表示回数を1つ増やす")
    func recordShown_incrementsShownCount() {
        // Arrange
        var record = PastThanksPromptDisplayRecord(day: today, shownCount: 1)

        // Act
        record.recordShown()

        // Assert
        #expect(record == .init(day: today, shownCount: 2))
    }

    // MARK: RawRepresentable

    @Test("端末に保存した文字列から、同じ記録に戻せる")
    func rawValue_roundTrip_restoresRecord() {
        // Arrange
        let record = PastThanksPromptDisplayRecord(day: today, shownCount: 1)

        // Act
        let actual = PastThanksPromptDisplayRecord(rawValue: record.rawValue)

        // Assert
        #expect(actual == record)
    }

}
