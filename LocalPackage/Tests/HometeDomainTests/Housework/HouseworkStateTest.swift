//
//  HouseworkStateTest.swift
//  hometeTests
//

import Foundation
@testable import HometeDomain
import Testing

struct HouseworkStateTest {

    @Test(
        "保存済みの値をデコードすると、対応するステータスになる",
        arguments: [
            ("incomplete", HouseworkState.incomplete),
            ("completed", .completed),
            ("notTodo", .notTodo),
        ]
    )
    func decode_knownCase_returnsSameState(rawValue: String, expected: HouseworkState) throws {
        // Arrange
        let data = Data(#"{"\#(rawValue)":{}}"#.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkState.self, from: data)

        // Assert
        #expect(actual == expected)
    }

    @Test("廃止した承認待ちの値をデコードすると、完了になる")
    func decode_pendingApproval_returnsCompleted() throws {
        // Arrange
        let data = Data(#"{"pendingApproval":{}}"#.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkState.self, from: data)

        // Assert
        #expect(actual == HouseworkState.completed)
    }

    @Test("承認待ちの家事を含むドキュメントをデコードしても、家事として読み出せる")
    func decode_houseworkItemWithPendingApproval_returnsCompletedItem() throws {
        // Arrange
        let json = """
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 100,
            "state": { "pendingApproval": {} },
            "executorId": "executorId",
            "executedAt": 0,
            "expiredAt": 0
        }
        """
        let data = Data(json.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: "id1",
            indexedDate: Date(timeIntervalSinceReferenceDate: .zero),
            title: "洗濯",
            point: 100,
            state: .completed,
            executorId: "executorId",
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            expiredAt: Date(timeIntervalSinceReferenceDate: .zero)
        )
        #expect(actual == expected)
    }

}
