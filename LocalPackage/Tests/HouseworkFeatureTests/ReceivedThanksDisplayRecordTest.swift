//
//  ReceivedThanksDisplayRecordTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct ReceivedThanksDisplayRecordTest {

    private let calendar = Calendar.japanese
    private let now = Date.previewDate(year: 2026, month: 10, day: 6, hour: 8)
    private let today = Date.previewDate(year: 2026, month: 10, day: 6, hour: 0)
    private let receivedThanks = ReceivedThanksSummary(
        count: 1,
        senderNames: ["はなこ"],
        latestSentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)
    )

    // MARK: reconciled

    @Test("まだ記録していなければ、今日の記録として数え始める")
    func reconciled_noRecord_startsToday() {
        // Arrange
        let record = ReceivedThanksDisplayRecord()

        // Act
        let actual = record.reconciled(with: receivedThanks, now: now, calendar: calendar)

        // Assert
        #expect(actual == .init(day: today))
    }

    @Test("日付が変わったら、表示回数と×の状態を戻す")
    func reconciled_dayChanged_resetsRecord() {
        // Arrange
        let record = ReceivedThanksDisplayRecord(
            day: .previewDate(year: 2026, month: 10, day: 5, hour: 0),
            shownCount: 3,
            dismissedLatestSentAt: .previewDate(year: 2026, month: 10, day: 5, hour: 20)
        )

        // Act
        let actual = record.reconciled(with: receivedThanks, now: now, calendar: calendar)

        // Assert
        #expect(actual == .init(day: today))
    }

    @Test("×で閉じた後に新しいありがとうが届いたら、表示回数を0に戻してまた出せるようにする")
    func reconciled_newThanksAfterDismiss_resetsRecord() {
        // Arrange
        let record = ReceivedThanksDisplayRecord(
            day: today,
            shownCount: 2,
            dismissedLatestSentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 6)
        )

        // Act
        let actual = record.reconciled(with: receivedThanks, now: now, calendar: calendar)

        // Assert
        #expect(actual == .init(day: today))
    }

    @Test("×で閉じた後に新しいありがとうが届いていなければ、閉じたままにする")
    func reconciled_noNewThanksAfterDismiss_keepsRecord() {
        // Arrange
        let record = ReceivedThanksDisplayRecord(
            day: today,
            shownCount: 2,
            dismissedLatestSentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)
        )

        // Act
        let actual = record.reconciled(with: receivedThanks, now: now, calendar: calendar)

        // Assert
        #expect(actual == record)
    }

    // MARK: canShow

    @Test(
        "今日の表示回数が上限に満たず、×で閉じていなければ出す。上限に達していても、今の表示で数えた回なら出し続ける",
        arguments: [
            (shownCount: 0, isCounted: false, expected: true),
            (shownCount: 2, isCounted: false, expected: true),
            (shownCount: 3, isCounted: false, expected: false),
            (shownCount: 3, isCounted: true, expected: true),
        ]
    )
    func canShow_shownCount(shownCount: Int, isCounted: Bool, expected: Bool) {
        // Arrange
        let record = ReceivedThanksDisplayRecord(day: today, shownCount: shownCount)

        // Act
        let actual = record.canShow(receivedThanks, isCountedInCurrentAppearance: isCounted)

        // Assert
        #expect(actual == expected)
    }

    @Test("×で閉じていたら、今の表示で数えた回でも出さない")
    func canShow_dismissed_returnsFalse() {
        // Arrange
        var record = ReceivedThanksDisplayRecord(day: today, shownCount: 1)
        record.dismiss(receivedThanks)

        // Act
        let actual = record.canShow(receivedThanks, isCountedInCurrentAppearance: true)

        // Assert
        #expect(actual == false)
    }

    @Test("今日ありがとうが届いていなければ出さない")
    func canShow_notReceived_returnsFalse() {
        // Arrange
        let record = ReceivedThanksDisplayRecord(day: today)

        // Act
        let actual = record.canShow(
            .init(count: 0, senderNames: [], latestSentAt: nil),
            isCountedInCurrentAppearance: false
        )

        // Assert
        #expect(actual == false)
    }

    // MARK: recordShown / dismiss

    @Test("出したら表示回数を1つ進める")
    func recordShown_incrementsShownCount() {
        // Arrange
        var record = ReceivedThanksDisplayRecord(day: today, shownCount: 1)

        // Act
        record.recordShown()

        // Assert
        #expect(record == .init(day: today, shownCount: 2))
    }

    @Test("×で閉じたら、そのときに最後に届いていたありがとうの日時を覚える")
    func dismiss_recordsLatestSentAt() {
        // Arrange
        var record = ReceivedThanksDisplayRecord(day: today, shownCount: 1)

        // Act
        record.dismiss(receivedThanks)

        // Assert
        let expected = ReceivedThanksDisplayRecord(
            day: today,
            shownCount: 1,
            dismissedLatestSentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)
        )
        #expect(record == expected)
    }

    @Test("端末に保存した文字列から、同じ記録に戻せる")
    func rawValue_roundTrip() {
        // Arrange
        let record = ReceivedThanksDisplayRecord(
            day: today,
            shownCount: 2,
            dismissedLatestSentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)
        )

        // Act
        let actual = ReceivedThanksDisplayRecord(rawValue: record.rawValue)

        // Assert
        #expect(actual == record)
    }

}
