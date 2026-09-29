//
//  HouseworkItemTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation
@testable import HometeDomain
import Testing

enum HouseworkItemTest {

    struct UpdateStateCase {}
    struct ThanksCase {}

}

// MARK: - UpdateStateCase

extension HouseworkItemTest.UpdateStateCase {

    @Test("完了状態に更新すると、state・executorId・executedAtが更新される")
    func updateCompleted_updatesStateAndExecutorInfo() {
        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .incomplete,
            expiredAt: expiredAt
        )
        let now = Date()
        let executorId = "executorId"

        // Act
        let result = item.updateCompleted(at: now, executor: executorId)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .completed,
            executorId: executorId,
            executedAt: now,
            expiredAt: expiredAt
        )
        #expect(result == expected)
    }

    @Test("未完了状態に戻すと、stateがincompleteになり実行者情報がクリアされる")
    func updateIncomplete_clearsExecutorInfo() {
        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .completed,
            executorId: "executorId",
            executedAt: Date(),
            expiredAt: expiredAt
        )

        // Act
        let result = item.updateIncomplete()

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .incomplete,
            expiredAt: expiredAt
        )
        #expect(result == expected)
    }

    @Test("やらない状態に更新しても、実行者情報は保持される")
    func updateNotTodo_keepsExecutorInfo() {
        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let executedAt = Date().addingTimeInterval(-3600)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .completed,
            executorId: "executorId",
            executedAt: executedAt,
            expiredAt: expiredAt
        )

        // Act
        let result = item.updateNotTodo()

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .notTodo,
            executorId: "executorId",
            executedAt: executedAt,
            expiredAt: expiredAt
        )
        #expect(result == expected)
    }

}

// MARK: - ThanksCase

extension HouseworkItemTest.ThanksCase {

    @Test("ありがとうを追加すると、ステータスは変えずに届いた順で末尾に積まれる")
    func addingThanks_appendsThanksKeepingState() {
        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let executedAt = Date().addingTimeInterval(-3600)
        let firstThanks = HouseworkThanks(senderId: "sender1", comment: "ありがとう", sentAt: .distantPast)
        let secondThanks = HouseworkThanks(senderId: "sender2", comment: "助かりました", sentAt: .distantFuture)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: executedAt,
            expiredAt: expiredAt,
            thanks: [firstThanks]
        )

        // Act
        let result = item.addingThanks(secondThanks)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: executedAt,
            expiredAt: expiredAt,
            thanks: [firstThanks, secondThanks]
        )
        #expect(result == expected)
    }

    @Test("未完了に戻すと、完了に対して届いたありがとうもクリアされる")
    func updateIncomplete_clearsThanks() {
        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: Date(),
            expiredAt: expiredAt,
            thanks: [.init(senderId: "sender", comment: "ありがとう", sentAt: .distantPast)]
        )

        // Act
        let result = item.updateIncomplete()

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .incomplete,
            expiredAt: expiredAt
        )
        #expect(result == expected)
    }

    @Test("完了にし直しても、届いたありがとうを引き継ぐ")
    func updateCompleted_keepsThanks() {
        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let now = Date()
        let thanks = [HouseworkThanks(senderId: "sender", comment: "ありがとう", sentAt: .distantPast)]
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast,
            expiredAt: expiredAt,
            thanks: thanks
        )

        // Act
        let result = item.updateCompleted(at: now, executor: "executorId")

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: now,
            expiredAt: expiredAt,
            thanks: thanks
        )
        #expect(result == expected)
    }

    @Test("やらないに変更しても、届いたありがとうを引き継ぐ")
    func updateNotTodo_keepsThanks() {
        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let thanks = [HouseworkThanks(senderId: "sender", comment: "ありがとう", sentAt: .distantPast)]
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast,
            expiredAt: expiredAt,
            thanks: thanks
        )

        // Act
        let result = item.updateNotTodo()

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .notTodo,
            executorId: "executorId",
            executedAt: .distantPast,
            expiredAt: expiredAt,
            thanks: thanks
        )
        #expect(result == expected)
    }

    @Test("もう一度やったとして作る家事は別の完了なので、元の家事のありがとうを引き継がない")
    func makeRedone_doesNotKeepThanks() {
        // Arrange
        let indexedDate = Date()
        let expiredAt = Date().addingTimeInterval(3600)
        let now = Date()
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: .distantPast,
            expiredAt: expiredAt,
            thanks: [.init(senderId: "sender", comment: "ありがとう", sentAt: .distantPast)]
        )

        // Act
        let result = item.makeRedone(id: "id2", at: now, executor: "executorId")

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: now,
            expiredAt: expiredAt
        )
        #expect(result == expected)
    }

    @Test("ありがとうを含む家事をエンコードしてデコードし直しても、ありがとうが保たれる")
    func encodeDecode_keepsThanks() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date(timeIntervalSinceReferenceDate: .zero),
            state: .completed,
            executorId: "executorId",
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            expiredAt: Date(timeIntervalSinceReferenceDate: .zero),
            thanks: [.init(senderId: "sender", comment: "ありがとう", sentAt: Date(timeIntervalSinceReferenceDate: .zero))]
        )

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: JSONEncoder().encode(item))

        // Assert
        #expect(actual == item)
    }

    @Test("ありがとうを含むドキュメントをデコードすると、ありがとうも読み出せる")
    func decode_withThanks_returnsItemWithThanks() throws {
        // Arrange
        let json = """
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 100,
            "state": { "completed": {} },
            "executorId": "executorId",
            "executedAt": 0,
            "expiredAt": 0,
            "thanks": [
                { "senderId": "sender", "comment": "ありがとう", "sentAt": 0 }
            ]
        }
        """

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: Data(json.utf8))

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: "id1",
            indexedDate: Date(timeIntervalSinceReferenceDate: .zero),
            title: "洗濯",
            point: 100,
            state: .completed,
            executorId: "executorId",
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            expiredAt: Date(timeIntervalSinceReferenceDate: .zero),
            thanks: [
                .init(senderId: "sender", comment: "ありがとう", sentAt: Date(timeIntervalSinceReferenceDate: .zero)),
            ]
        )
        #expect(actual == expected)
    }

    @Test("ありがとうを保存する前に登録された家事をデコードすると、ありがとうは空として読み出せる")
    func decode_withoutThanks_returnsEmptyThanks() throws {
        // Arrange
        let json = """
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 100,
            "state": { "completed": {} },
            "executorId": "executorId",
            "executedAt": 0,
            "expiredAt": 0
        }
        """

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: Data(json.utf8))

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
