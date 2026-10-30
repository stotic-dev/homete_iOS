//
//  HouseworkItemPostponeTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeModel
import Testing

enum HouseworkItemPostponeTest {

    struct CodableCase {}
    struct CarryOverCase {}

    static let sourceDate = Date.previewDate(year: 2026, month: 1, day: 10)
    static let destinationDate = Date.previewDate(year: 2026, month: 1, day: 11)
    /// `makeForTest`の`expiredAt`の既定値は呼び出すたびの現在日時なので、比べる家事では固定する
    static let expiredAt = Date.previewDate(year: 2027, month: 1, day: 11)

}

// MARK: - Codable

extension HouseworkItemPostponeTest.CodableCase {

    @Test("エンコードしてデコードすると、まわす前の日付・まわした先の日付も元に戻る")
    func encodeDecode_withPostponedDates_restoresItem() throws {
        // Arrange
        let input = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkItemPostponeTest.sourceDate,
            state: .notTodo,
            expiredAt: .previewDate(year: 2027, month: 1, day: 10),
            createdAt: .previewDate(year: 2026, month: 1, day: 9),
            postponedFrom: .init(value: .previewDate(year: 2026, month: 1, day: 9)),
            postponedTo: .init(value: HouseworkItemPostponeTest.destinationDate)
        )
        let data = try JSONEncoder().encode(input)

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        #expect(actual == input)
    }

    @Test("まわしていない家事は、まわす前の日付・まわした先の日付を書き出さない")
    func encode_withoutPostponedDates_omitsFields() throws {
        // Arrange
        let input = HouseworkItem.makeForTest(id: "1", indexedDate: HouseworkItemPostponeTest.sourceDate)

        // Act
        let data = try JSONEncoder().encode(input)

        // Assert
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let actualKeys = Set((object ?? [:]).keys)
        #expect(actualKeys.isDisjoint(with: ["postponedFrom", "postponedTo"]))
    }

}

// MARK: - 引き継ぎ

extension HouseworkItemPostponeTest.CarryOverCase {

    @Test("まわしてきた家事を完了にしても、まわす前の日付は引き継がれる")
    func updateCompleted_keepsPostponedFrom() {
        // Arrange
        let input = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkItemPostponeTest.destinationDate,
            point: 10,
            expiredAt: HouseworkItemPostponeTest.expiredAt,
            postponedFrom: .init(value: HouseworkItemPostponeTest.sourceDate)
        )
        let completedAt = Date.previewDate(year: 2026, month: 1, day: 11, hour: 9)
        let expected = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkItemPostponeTest.destinationDate,
            point: 10,
            state: .completed,
            executorId: "own",
            executedAt: completedAt,
            expiredAt: HouseworkItemPostponeTest.expiredAt,
            postponedFrom: .init(value: HouseworkItemPostponeTest.sourceDate)
        )

        // Act
        let actual = input.updateCompleted(
            at: completedAt,
            executors: [.solo(userId: "own", point: 10)],
            effort: .normal
        )

        // Assert
        #expect(actual == expected)
    }

    @Test("まわしてきた家事をやらないにしても、まわす前の日付は引き継がれる")
    func updateNotTodo_keepsPostponedFrom() {
        // Arrange
        let input = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkItemPostponeTest.destinationDate,
            expiredAt: HouseworkItemPostponeTest.expiredAt,
            postponedFrom: .init(value: HouseworkItemPostponeTest.sourceDate)
        )
        let expected = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkItemPostponeTest.destinationDate,
            state: .notTodo,
            expiredAt: HouseworkItemPostponeTest.expiredAt,
            postponedFrom: .init(value: HouseworkItemPostponeTest.sourceDate)
        )

        // Act
        let actual = input.updateNotTodo()

        // Assert
        #expect(actual == expected)
    }

    @Test("まわしてきた家事をもう一度まわすと、まわす前の日付は直前の日付になる")
    func postponed_alreadyPostponedItem_replacesPostponedFromWithPreviousDate() {
        // Arrange
        let input = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkItemPostponeTest.destinationDate,
            expiredAt: .previewDate(year: 2027, month: 1, day: 11),
            postponedFrom: .init(value: HouseworkItemPostponeTest.sourceDate)
        )
        let nextDestination = Date.previewDate(year: 2026, month: 1, day: 12)
        let expected = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: nextDestination,
            expiredAt: .previewDate(year: 2027, month: 1, day: 12),
            postponedFrom: .init(value: HouseworkItemPostponeTest.destinationDate)
        )

        // Act
        let actual = input.postponed(
            to: .init(
                indexedDate: .init(value: nextDestination),
                expiredAt: .previewDate(year: 2027, month: 1, day: 12)
            )
        )

        // Assert
        #expect(actual == expected)
    }

}
