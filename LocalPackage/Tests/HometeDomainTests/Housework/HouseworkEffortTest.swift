//
//  HouseworkEffortTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct HouseworkEffortTest {

    @Test(
        "頑張り度に応じてポイントを上乗せし、端数は切り上げる",
        arguments: [
            (HouseworkEffort.normal, 10, 10),
            (HouseworkEffort.hard, 10, 12),
            (HouseworkEffort.veryHard, 10, 15),
            // 3 × 1.2 = 3.6
            (HouseworkEffort.hard, 3, 4),
            // 3 × 1.5 = 4.5
            (HouseworkEffort.veryHard, 3, 5),
            // ポイントが小さい家事でも、頑張った分が必ず増える
            (HouseworkEffort.hard, 1, 2),
            (HouseworkEffort.veryHard, 1, 2),
            // 5 × 1.2 = 6 のように割り切れるときは切り上げない
            (HouseworkEffort.hard, 5, 6),
            (HouseworkEffort.normal, 0, 0),
        ]
    )
    func boostedPoint(effort: HouseworkEffort, point: Int, expected: Int) {
        let actual = effort.boostedPoint(point)

        #expect(actual == expected)
    }

    @Test(
        "Firestoreに保存した文字列を、対応する頑張り度として読む",
        arguments: [
            ("normal", HouseworkEffort.normal),
            ("hard", HouseworkEffort.hard),
            ("veryHard", HouseworkEffort.veryHard),
        ]
    )
    func decode_savedValue(rawValue: String, expected: HouseworkEffort) throws {
        // Arrange
        let data = Data("\"\(rawValue)\"".utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkEffort.self, from: data)

        // Assert
        #expect(actual == expected)
    }

    @Test("知らない値は、上乗せしないふつうとして読む")
    func decode_unknownValue_returnsNormal() throws {
        // Arrange
        let data = Data("\"superHard\"".utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkEffort.self, from: data)

        // Assert
        #expect(actual == .normal)
    }

    @Test(
        "頑張り度はケース名の文字列で保存する",
        arguments: [
            (HouseworkEffort.normal, "\"normal\""),
            (HouseworkEffort.hard, "\"hard\""),
            (HouseworkEffort.veryHard, "\"veryHard\""),
        ]
    )
    func encode_savesCaseName(effort: HouseworkEffort, expected: String) throws {
        // Act
        let data = try JSONEncoder().encode(effort)

        // Assert
        #expect(String(bytes: data, encoding: .utf8) == expected)
    }

    @Test("家事の獲得ポイントは、上乗せ前のポイントに頑張り度を反映したものになる")
    func earnedPoint_returnsBoostedPoint() {
        let item = HouseworkItem.makeForTest(id: 1, point: 10, state: .completed, effort: .veryHard)

        #expect(item.earnedPoint == 15)
    }

}
