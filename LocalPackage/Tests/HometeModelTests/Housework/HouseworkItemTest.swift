// swiftlint:disable file_length
//
//  HouseworkItemTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation
@testable import HometeModel
import Testing

enum HouseworkItemTest {

    struct UpdateStateCase {}
    struct UpdateExecutorsCase {}
    struct ThanksCase {}
    struct CodableCase {}
    struct MemoCase {}
    struct ImageCase {}

}

// MARK: - UpdateStateCase

extension HouseworkItemTest.UpdateStateCase {

    @Test("完了状態に更新すると、state・executors・effort・executedAtが更新され、pointは上乗せ前のまま")
    func updateCompleted_updatesStateAndExecutorInfo() {
        // Arrange
        let indexedDate = Date()
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .incomplete
        )
        let now = Date()
        let executors = [
            HouseworkExecutor(userId: "userA", percentage: 60, point: 72),
            HouseworkExecutor(userId: "userB", percentage: 40, point: 48),
        ]

        // Act
        let result = item.updateCompleted(at: now, executors: executors, effort: .hard)

        // Assert
        let expected = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: indexedDate),
            title: "洗濯",
            point: 100,
            state: .completed,
            executors: [
                HouseworkExecutor(userId: "userA", percentage: 60, point: 72),
                HouseworkExecutor(userId: "userB", percentage: 40, point: 48),
            ],
            effort: .hard,
            executedAt: now,
            templateHouseworkItemId: nil
        )
        #expect(result == expected)
    }

    @Test("もう一度やった家事は、元の家事の頑張り度に関係なく、ふつうで上乗せ前のポイントを満額配分する")
    func makeRedone_fromBoostedItem_returnsNormalEffort() {
        // Arrange
        let indexedDate = Date()
        let now = Date()
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .completed,
            executors: [HouseworkExecutor(userId: "userA", percentage: 100, point: 120)],
            effort: .hard,
            executedAt: Date()
        )

        // Act
        let result = item.makeRedone(id: "id2", at: now, executor: "userB")

        // Assert
        let expected = HouseworkItem(
            id: "id2",
            indexedDate: .init(value: indexedDate),
            title: "洗濯",
            point: 100,
            state: .completed,
            executors: [HouseworkExecutor(userId: "userB", percentage: 100, point: 100)],
            effort: .normal,
            executedAt: now,
            templateHouseworkItemId: nil,
            createdAt: now
        )
        #expect(result == expected)
    }

    @Test("未完了状態に戻すと、stateがincompleteになり実行者情報がクリアされ、頑張り度はふつうに戻る")
    func updateIncomplete_clearsExecutorInfo() {
        // Arrange
        let indexedDate = Date()
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .completed,
            executorId: "executorId",
            effort: .veryHard,
            executedAt: Date()
        )

        // Act
        let result = item.updateIncomplete()

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .incomplete
        )
        #expect(result == expected)
    }

    @Test("やらない状態に更新しても、実行者情報と頑張り度は保持される")
    func updateNotTodo_keepsExecutorInfo() {
        // Arrange
        let indexedDate = Date()
        let executedAt = Date().addingTimeInterval(-3600)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .completed,
            executors: [HouseworkExecutor(userId: "executorId", percentage: 100, point: 120)],
            effort: .hard,
            executedAt: executedAt
        )

        // Act
        let result = item.updateNotTodo()

        // Assert
        let expected = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: indexedDate),
            title: "洗濯",
            point: 100,
            state: .notTodo,
            executors: [HouseworkExecutor(userId: "executorId", percentage: 100, point: 120)],
            effort: .hard,
            executedAt: executedAt,
            templateHouseworkItemId: nil
        )
        #expect(result == expected)
    }

}

// MARK: - ThanksCase

extension HouseworkItemTest.ThanksCase {

    @Test("未完了に戻すと、届いていたありがとうの記録が消える")
    func updateIncomplete_clearsThanks() {
        // Arrange
        let indexedDate = Date()
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: Date(),
            thanks: ["senderId": .init(comment: "ありがとう", sentAt: Date())]
        )

        // Act
        let result = item.updateIncomplete()

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .incomplete
        )
        #expect(result == expected)
    }

    @Test("完了・未完了・やらないに更新しても、作成日時は変わらない")
    func updateState_keepsCreatedAt() {
        // Arrange
        let createdAt = Date(timeIntervalSince1970: 1000)
        let item = HouseworkItem.makeForTest(id: 1, createdAt: createdAt)

        // Act
        let result = item
            .updateCompleted(at: Date(), executors: [.solo(userId: "executorId", point: 100)], effort: .normal)
            .updateIncomplete()
            .updateNotTodo()

        // Assert
        #expect(result.createdAt == createdAt)
    }

    @Test("完了にすると、未完了の家事に残っていたありがとうの記録は引き継がない")
    func updateCompleted_clearsThanks() {
        // Arrange
        let indexedDate = Date()
        let now = Date()
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .incomplete,
            thanks: ["senderId": .init(comment: "ありがとう", sentAt: Date())]
        )

        // Act
        let result = item.updateCompleted(
            at: now,
            executors: [.solo(userId: "executorId", point: 100)],
            effort: .normal
        )

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: now
        )
        #expect(result == expected)
    }

    @Test("もう一度やった家事は、元の家事に届いたありがとうを引き継がない")
    func makeRedone_doesNotInheritThanks() {
        // Arrange
        let indexedDate = Date()
        let now = Date()
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: Date(),
            thanks: ["senderId": .init(comment: "ありがとう", sentAt: Date())]
        )

        // Act
        let result = item.makeRedone(id: "redoneId", at: now, executor: "executorId")

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: "redoneId",
            indexedDate: indexedDate,
            state: .completed,
            executorId: "executorId",
            executedAt: now,
            createdAt: now
        )
        #expect(result == expected)
    }

    @Test("ありがとうの記録を持たない既存の家事データは、ありがとうなしとして読み込める")
    func decode_withoutThanks_returnsEmptyThanks() throws {
        // Arrange
        let json = Data("""
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
        """.utf8)

        // Act
        let result = try JSONDecoder().decode(HouseworkItem.self, from: json)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date(timeIntervalSinceReferenceDate: 0),
            title: "洗濯",
            state: .completed,
            executorId: "executorId",
            executedAt: Date(timeIntervalSinceReferenceDate: 0)
        )
        #expect(result == expected)
    }

    @Test("エンコードしてデコードすると、届いたありがとうの記録も元に戻る")
    func encodeThenDecode_keepsThanks() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date(timeIntervalSinceReferenceDate: .zero),
            state: .completed,
            executorId: "executorId",
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            thanks: ["senderId": .init(comment: "ありがとう", sentAt: Date(timeIntervalSinceReferenceDate: .zero))]
        )

        // Act
        let data = try JSONEncoder().encode(item)
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date(timeIntervalSinceReferenceDate: .zero),
            state: .completed,
            executorId: "executorId",
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            thanks: ["senderId": .init(comment: "ありがとう", sentAt: Date(timeIntervalSinceReferenceDate: .zero))]
        )
        #expect(actual == expected)
    }

}

// MARK: - CodableCase

extension HouseworkItemTest.CodableCase {

    /// 旧バージョンのアプリが読む項目だけを持つ型
    struct LegacyHouseworkItem: Decodable, Equatable {

        let id: String
        let point: Int
        let executorId: String?

    }

    @Test("executorsが無い旧形式のドキュメントは、executorIdの人に満額配分したものとして読む")
    func decode_legacyDocument_returnsSoloExecutor() throws {
        // Arrange
        let json = """
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 10,
            "state": { "completed": {} },
            "executorId": "userA",
            "executedAt": 0,
            "expiredAt": 0
        }
        """
        let data = Data(json.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        let expected = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: Date(timeIntervalSinceReferenceDate: .zero)),
            title: "洗濯",
            point: 10,
            state: .completed,
            executors: [HouseworkExecutor(userId: "userA", percentage: 100, point: 10)],
            effort: .normal,
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            templateHouseworkItemId: nil
        )
        #expect(actual == expected)
    }

    @Test("effortが無いドキュメントは、頑張り度をふつうとして読む")
    func decode_documentWithoutEffort_returnsNormalEffort() throws {
        // Arrange
        let json = """
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 10,
            "state": { "completed": {} },
            "executors": [{ "userId": "userA", "percentage": 100, "point": 10 }],
            "executorId": "userA",
            "executedAt": 0,
            "expiredAt": 0
        }
        """
        let data = Data(json.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        let expected = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: Date(timeIntervalSinceReferenceDate: .zero)),
            title: "洗濯",
            point: 10,
            state: .completed,
            executors: [HouseworkExecutor(userId: "userA", percentage: 100, point: 10)],
            effort: .normal,
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            templateHouseworkItemId: nil
        )
        #expect(actual == expected)
    }

    @Test(
        "知らない頑張り度のドキュメントでも、獲得ポイントは担当者のポイントの合計と一致する",
        arguments: [
            // 新しいアプリが保存した、今のアプリが知らない頑張り度
            #""effort": "superHard","#,
            // 頑張り度を知らない旧バージョンのアプリが上書きして、effortだけが消えた
            "",
        ]
    )
    func decode_effortNotMatchingExecutors_earnedPointEqualsExecutorsTotal(effortField: String) throws {
        // Arrange
        let json = """
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 10,
            "state": { "completed": {} },
            "executors": [
                { "userId": "userA", "percentage": 50, "point": 10 },
                { "userId": "userB", "percentage": 50, "point": 10 }
            ],
            \(effortField)
            "executorId": "userA",
            "executedAt": 0,
            "expiredAt": 0
        }
        """
        let item = try JSONDecoder().decode(HouseworkItem.self, from: Data(json.utf8))

        // Act
        let actual = item.earnedPoint

        // Assert
        #expect(actual == 20)
    }

    @Test("executorsとexecutorIdの両方があるドキュメントは、executorsを優先して読む")
    func decode_documentWithExecutors_prefersExecutors() throws {
        // Arrange
        let json = """
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 10,
            "state": { "completed": {} },
            "executors": [
                { "userId": "userA", "percentage": 70, "point": 7 },
                { "userId": "userB", "percentage": 30, "point": 3 }
            ],
            "executorId": "userA",
            "executedAt": 0,
            "expiredAt": 0
        }
        """
        let data = Data(json.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        let expected = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: Date(timeIntervalSinceReferenceDate: .zero)),
            title: "洗濯",
            point: 10,
            state: .completed,
            executors: [
                HouseworkExecutor(userId: "userA", percentage: 70, point: 7),
                HouseworkExecutor(userId: "userB", percentage: 30, point: 3),
            ],
            effort: .normal,
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            templateHouseworkItemId: nil
        )
        #expect(actual == expected)
    }

    @Test("未完了で実行者の無いドキュメントは、担当者なしとして読む")
    func decode_documentWithoutExecutor_returnsNoExecutors() throws {
        // Arrange
        let json = """
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 10,
            "state": { "incomplete": {} },
            "expiredAt": 0
        }
        """
        let data = Data(json.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        let expected = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: Date(timeIntervalSinceReferenceDate: .zero)),
            title: "洗濯",
            point: 10,
            state: .incomplete,
            executors: [],
            effort: .normal,
            executedAt: nil,
            templateHouseworkItemId: nil
        )
        #expect(actual == expected)
    }

    @Test("エンコードすると、旧バージョンのアプリは1人目の担当者を実行者として読める")
    func encode_multipleExecutors_legacyAppReadsFirstExecutor() throws {
        // Arrange
        let item = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: Date(timeIntervalSinceReferenceDate: .zero)),
            title: "洗濯",
            point: 10,
            state: .completed,
            executors: [
                HouseworkExecutor(userId: "userA", percentage: 70, point: 7),
                HouseworkExecutor(userId: "userB", percentage: 30, point: 3),
            ],
            effort: .normal,
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            templateHouseworkItemId: nil
        )

        // Act
        let data = try JSONEncoder().encode(item)

        // Assert
        let actual = try JSONDecoder().decode(LegacyHouseworkItem.self, from: data)
        let expected = LegacyHouseworkItem(id: "id1", point: 10, executorId: "userA")
        #expect(actual == expected)
    }

    @Test("エンコードしてデコードすると、作成日時も含めて元の家事に戻る")
    func encodeThenDecode_returnsSameItem() throws {
        // Arrange
        let item = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: Date(timeIntervalSinceReferenceDate: .zero)),
            title: "洗濯",
            point: 10,
            state: .completed,
            executors: [
                HouseworkExecutor(userId: "userA", percentage: 70, point: 11),
                HouseworkExecutor(userId: "userB", percentage: 30, point: 4),
            ],
            effort: .veryHard,
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            templateHouseworkItemId: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 100)
        )

        // Act
        let data = try JSONEncoder().encode(item)
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        let expected = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: Date(timeIntervalSinceReferenceDate: .zero)),
            title: "洗濯",
            point: 10,
            state: .completed,
            executors: [
                HouseworkExecutor(userId: "userA", percentage: 70, point: 11),
                HouseworkExecutor(userId: "userB", percentage: 30, point: 4),
            ],
            effort: .veryHard,
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            templateHouseworkItemId: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 100)
        )
        #expect(actual == expected)
    }

    @Test("保持期限が付く前の家事（expiredAtが無いドキュメント）も読み込める")
    func decode_withoutExpiredAt_succeeds() throws {
        // Arrange
        let json = Data("""
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 100,
            "state": { "incomplete": {} }
        }
        """.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: json)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date(timeIntervalSinceReferenceDate: 0),
            title: "洗濯"
        )
        #expect(actual == expected)
    }

    @Test("エンコードしても、Cloud Functionsだけが書く保持期限（expiredAt）は書き出さない")
    func encode_doesNotWriteExpiredAt() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date(timeIntervalSinceReferenceDate: .zero),
            state: .completed,
            executorId: "executorId",
            executedAt: Date(timeIntervalSinceReferenceDate: .zero),
            createdAt: Date(timeIntervalSinceReferenceDate: .zero)
        )

        // Act
        let data = try JSONEncoder().encode(item)

        // Assert
        let actual = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any]).keys
        let expected = [
            "id", "indexedDate", "title", "point", "state", "executors", "effort",
            "executorId", "executedAt", "thanks", "createdAt",
        ]
        #expect(Set(actual) == Set(expected))
    }

    @Test("既存の家事を書き換えるときは、保持期限（expiredAt）と画像の参照（images）を書かない")
    func writtenFieldNames_excludesExpiredAt() {
        // Act
        let actual = HouseworkItem.writtenFieldNames

        // Assert
        let expected = [
            "id", "indexedDate", "title", "point", "state", "executors", "effort", "executorId",
            "executedAt", "templateHouseworkItemId", "thanks", "createdAt", "memo", "postponedFrom", "postponedTo",
        ]
        #expect(actual == expected)
    }

    @Test("家事のドキュメントを新しく作るときは、画像の参照も書く")
    func creationFieldNames_includesImages() {
        // Act
        let actual = HouseworkItem.creationFieldNames

        // Assert
        let expected = [
            "id", "indexedDate", "title", "point", "state", "executors", "effort", "executorId",
            "executedAt", "templateHouseworkItemId", "thanks", "createdAt", "memo", "postponedFrom", "postponedTo",
            "images",
        ]
        #expect(actual == expected)
    }

}

// MARK: - UpdateExecutorsCase

extension HouseworkItemTest.UpdateExecutorsCase {

    @Test("完了済みの家事の担当者を入れ替えても、完了日時・頑張り度・ありがとうは変わらない")
    func updateExecutors_completedItem_keepsCompletionRecord() {
        // Arrange
        let indexedDate = Date()
        let executedAt = Date()
        let thanks = ["userB": HouseworkThanks(comment: "ありがとう", sentAt: Date())]
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: indexedDate,
            title: "洗濯",
            point: 100,
            state: .completed,
            executors: [HouseworkExecutor(userId: "userA", percentage: 100, point: 120)],
            effort: .hard,
            executedAt: executedAt,
            thanks: thanks,
            createdAt: executedAt
        )
        let executors = [
            HouseworkExecutor(userId: "userA", percentage: 50, point: 60),
            HouseworkExecutor(userId: "userB", percentage: 50, point: 60),
        ]

        // Act
        let result = item.updateExecutors(executors)

        // Assert
        let expected = HouseworkItem(
            id: "id1",
            indexedDate: .init(value: indexedDate),
            title: "洗濯",
            point: 100,
            state: .completed,
            executors: [
                HouseworkExecutor(userId: "userA", percentage: 50, point: 60),
                HouseworkExecutor(userId: "userB", percentage: 50, point: 60),
            ],
            effort: .hard,
            executedAt: executedAt,
            templateHouseworkItemId: nil,
            thanks: thanks,
            createdAt: executedAt
        )
        #expect(result == expected)
    }

    @Test(
        "完了していない家事の担当者は入れ替えない",
        arguments: [HouseworkState.incomplete, .notTodo]
    )
    func updateExecutors_notCompletedItem_returnsSelf(state: HouseworkState) {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            title: "洗濯",
            point: 100,
            state: state
        )

        // Act
        let result = item.updateExecutors([.solo(userId: "userA", point: 100)])

        // Assert
        #expect(result == item)
    }

}

// MARK: - MemoCase

extension HouseworkItemTest.MemoCase {

    static let memo = HouseworkMemo(
        text: "スーパーで",
        checklist: [.init(id: "1", title: "牛乳", isChecked: true)]
    )

    @Test("完了にしても、メモは引き継がれる")
    func updateCompleted_keepsMemo() {
        // Arrange
        let date = Date(timeIntervalSinceReferenceDate: .zero)
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: date, point: 10, memo: Self.memo)

        // Act
        let actual = item.updateCompleted(at: date, executors: [.solo(userId: "userA", point: 10)], effort: .normal)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: date,
            point: 10,
            state: .completed,
            executorId: "userA",
            executedAt: date,
            memo: Self.memo
        )
        #expect(actual == expected)
    }

    @Test("手伝った人を足しても、メモは引き継がれる")
    func updateExecutors_keepsMemo() {
        // Arrange
        let date = Date(timeIntervalSinceReferenceDate: .zero)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: date,
            point: 10,
            state: .completed,
            executorId: "userA",
            executedAt: date,
            memo: Self.memo
        )
        let executors = [
            HouseworkExecutor(userId: "userA", percentage: 50, point: 5),
            HouseworkExecutor(userId: "userB", percentage: 50, point: 5),
        ]

        // Act
        let actual = item.updateExecutors(executors)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: date,
            point: 10,
            state: .completed,
            executors: executors,
            executedAt: date,
            memo: Self.memo
        )
        #expect(actual == expected)
    }

    @Test("もう一度やった家事は、元の家事のメモをチェック状態ごと引き継ぐ")
    func makeRedone_keepsMemo() {
        // Arrange
        let date = Date(timeIntervalSinceReferenceDate: .zero)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: date,
            point: 10,
            state: .completed,
            executorId: "userA",
            executedAt: date,
            memo: Self.memo
        )

        // Act
        let actual = item.makeRedone(id: "id2", at: date, executor: "userB")

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: date,
            point: 10,
            state: .completed,
            executorId: "userB",
            executedAt: date,
            createdAt: date,
            memo: Self.memo
        )
        #expect(actual == expected)
    }

    @Test("未完了に戻しても、メモは引き継がれる")
    func updateIncomplete_keepsMemo() {
        // Arrange
        let date = Date(timeIntervalSinceReferenceDate: .zero)
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: date,
            state: .completed,
            executorId: "userA",
            executedAt: date,
            memo: Self.memo
        )

        // Act
        let actual = item.updateIncomplete()

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: date, memo: Self.memo)
        #expect(actual == expected)
    }

    @Test("やらないにしても、メモは引き継がれる")
    func updateNotTodo_keepsMemo() {
        // Arrange
        let date = Date(timeIntervalSinceReferenceDate: .zero)
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: date, memo: Self.memo)

        // Act
        let actual = item.updateNotTodo()

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: date,
            state: .notTodo,
            memo: Self.memo
        )
        #expect(actual == expected)
    }

    @Test("作成日時を付けても、メモは引き継がれる")
    func updateCreatedAt_keepsMemo() {
        // Arrange
        let date = Date(timeIntervalSinceReferenceDate: .zero)
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: date, memo: Self.memo)

        // Act
        let actual = item.updateCreatedAt(date)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: date,
            createdAt: date,
            memo: Self.memo
        )
        #expect(actual == expected)
    }

    @Test("メモを更新すると、メモだけが変わる")
    func updateMemo_replacesOnlyMemo() throws {
        // Arrange
        let date = Date(timeIntervalSinceReferenceDate: .zero)
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: date, createdAt: date)

        // Act
        let actual = try item.updateMemo(Self.memo, limitPolicy: .free)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: date,
            createdAt: date,
            memo: Self.memo
        )
        #expect(actual == expected)
    }

    @Test(
        "メモを編集できるのは未完了の家事だけ",
        arguments: [
            (HouseworkState.incomplete, true),
            (.completed, false),
            (.notTodo, false),
        ]
    )
    func canEditMemo(state: HouseworkState, expected: Bool) {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, state: state)

        // Act
        let actual = item.canEditMemo

        // Assert
        #expect(actual == expected)
    }

    @Test("メモを持たない既存の家事データは、メモなしとして読み込める")
    func decode_withoutMemo_returnsNilMemo() throws {
        // Arrange
        let json = Data("""
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 100,
            "state": { "incomplete": {} },
            "expiredAt": 0
        }
        """.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: json)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Date(timeIntervalSinceReferenceDate: 0),
            title: "洗濯"
        )
        #expect(actual == expected)
    }

    @Test(
        "エンコードしてデコードすると、メモも元に戻る（消したメモは空のまま残る）",
        arguments: [
            Self.memo,
            HouseworkMemo.empty,
        ]
    )
    func encodeThenDecode_keepsMemo(memo: HouseworkMemo) throws {
        // Arrange
        let date = Date(timeIntervalSinceReferenceDate: .zero)
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: date, memo: memo)

        // Act
        let data = try JSONEncoder().encode(item)
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: date, memo: memo)
        #expect(actual == expected)
    }

    @Test("メモを一度も書いていない家事は、memoを書き出さない")
    func encode_withoutMemo_omitsMemoKey() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1)

        // Act
        let data = try JSONEncoder().encode(item)

        // Assert
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(object?["memo"] == nil)
    }

}

// MARK: - ImageCase

extension HouseworkItemTest.ImageCase {

    static let date = Date(timeIntervalSinceReferenceDate: .zero)
    static let image = HouseworkImage(
        id: "image1",
        storagePath: "Cohabitant/c1/Houseworks/id1/image1.jpg",
        uploaderId: "userA"
    )
    static let otherImage = HouseworkImage(
        id: "image2",
        storagePath: "Cohabitant/c1/Houseworks/id1/image2.jpg",
        uploaderId: "userB"
    )

    @Test("画像の保存先は、同居人グループと家事ごとのフォルダになる")
    func make_storagePath_isUnderCohabitantAndHousework() {
        // Act
        let actual = HouseworkImage.make(id: "image1", houseworkId: "id1", cohabitantId: "c1", uploaderId: "userA")

        // Assert
        #expect(actual == Self.image)
    }

    @Test("完了にしても、画像は引き継がれる")
    func updateCompleted_keepsImages() {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, point: 10, images: [Self.image])

        // Act
        let actual = item.updateCompleted(
            at: Self.date,
            executors: [.solo(userId: "userA", point: 10)],
            effort: .normal
        )

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Self.date,
            point: 10,
            state: .completed,
            executorId: "userA",
            executedAt: Self.date,
            images: [Self.image]
        )
        #expect(actual == expected)
    }

    @Test("手伝った人を足しても、画像は引き継がれる")
    func updateExecutors_keepsImages() {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Self.date,
            point: 10,
            state: .completed,
            executorId: "userA",
            executedAt: Self.date,
            images: [Self.image]
        )
        let executors = [
            HouseworkExecutor(userId: "userA", percentage: 50, point: 5),
            HouseworkExecutor(userId: "userB", percentage: 50, point: 5),
        ]

        // Act
        let actual = item.updateExecutors(executors)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Self.date,
            point: 10,
            state: .completed,
            executors: executors,
            executedAt: Self.date,
            images: [Self.image]
        )
        #expect(actual == expected)
    }

    @Test("未完了に戻しても、画像は引き継がれる")
    func updateIncomplete_keepsImages() {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Self.date,
            state: .completed,
            executorId: "userA",
            executedAt: Self.date,
            images: [Self.image]
        )

        // Act
        let actual = item.updateIncomplete()

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])
        #expect(actual == expected)
    }

    @Test("やらないにしても、画像は引き継がれる")
    func updateNotTodo_keepsImages() {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])

        // Act
        let actual = item.updateNotTodo()

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, state: .notTodo, images: [Self.image])
        #expect(actual == expected)
    }

    @Test("作成日時を付けても、画像は引き継がれる")
    func updateCreatedAt_keepsImages() {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])

        // Act
        let actual = item.updateCreatedAt(Self.date)

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Self.date,
            createdAt: Self.date,
            images: [Self.image]
        )
        #expect(actual == expected)
    }

    @Test("メモを更新しても、画像は引き継がれる")
    func updateMemo_keepsImages() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])

        // Act
        let actual = try item.updateMemo(.empty, limitPolicy: .free)

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, memo: .empty, images: [Self.image])
        #expect(actual == expected)
    }

    @Test("同じIDのまま別の日へまわしても、画像は引き継がれる")
    func postponed_keepsImages() {
        // Arrange
        let destinationDate = Self.date.addingTimeInterval(86400)
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])

        // Act
        let actual = item.postponed(to: .init(indexedDate: .init(value: destinationDate)))

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: destinationDate,
            postponedFrom: .init(value: Self.date),
            images: [Self.image]
        )
        #expect(actual == expected)
    }

    @Test("テンプレートの家事を別の日へまわしたときに元の日に残す記録は、画像を持ち続ける")
    func markedAsPostponed_keepsImages() {
        // Arrange
        let destinationDate = Self.date.addingTimeInterval(86400)
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])

        // Act
        let actual = item.markedAsPostponed(to: .init(value: destinationDate))

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Self.date,
            state: .notTodo,
            postponedTo: .init(value: destinationDate),
            images: [Self.image]
        )
        #expect(actual == expected)
    }

    @Test("テンプレートの家事を別の日へまわすときに作る家事は、画像を引き継がない")
    func makePostponedCopy_doesNotInheritImages() {
        // Arrange
        let destinationDate = Self.date.addingTimeInterval(86400)
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])

        // Act
        let actual = item.makePostponedCopy(
            id: "id2",
            to: .init(indexedDate: .init(value: destinationDate)),
            at: Self.date
        )

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: destinationDate,
            createdAt: Self.date,
            postponedFrom: .init(value: Self.date)
        )
        #expect(actual == expected)
    }

    @Test("もう一度やった家事は、画像を引き継がない")
    func makeRedone_doesNotInheritImages() {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Self.date,
            point: 10,
            state: .completed,
            executorId: "userA",
            executedAt: Self.date,
            images: [Self.image]
        )

        // Act
        let actual = item.makeRedone(id: "id2", at: Self.date, executor: "userB")

        // Assert
        let expected = HouseworkItem.makeForTest(
            id: 2,
            indexedDate: Self.date,
            point: 10,
            state: .completed,
            executorId: "userB",
            executedAt: Self.date,
            createdAt: Self.date
        )
        #expect(actual == expected)
    }

    @Test("プレミアムプランなら、今ある画像の後ろに画像を添えられる")
    func addingImages_premium_appendsImages() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])

        // Act
        let actual = try item.addingImages([Self.otherImage], policy: .premium)

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image, Self.otherImage])
        #expect(actual == expected)
    }

    @Test("画像を一度も添えていない家事にも、画像を添えられる")
    func addingImages_withoutImages_createsImages() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date)

        // Act
        let actual = try item.addingImages([Self.image], policy: .premium)

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])
        #expect(actual == expected)
    }

    @Test(
        "画像を添えられない場合はエラーになる",
        arguments: [
            (HouseworkState.completed, HouseworkImagePolicy.premium, 0, HouseworkImageError.notEditable),
            (.notTodo, .premium, 0, .notEditable),
            (.incomplete, .free, 0, .premiumRequired),
            (.incomplete, .premium, 10, .limitExceeded),
        ]
    )
    func addingImages_notAllowed_throws(
        state: HouseworkState,
        policy: HouseworkImagePolicy,
        currentCount: Int,
        expected: HouseworkImageError
    ) {
        // Arrange
        let images = (0 ..< currentCount).map {
            HouseworkImage(id: "image\($0)", storagePath: "path\($0)", uploaderId: "userA")
        }
        let item = HouseworkItem.makeForTest(id: 1, state: state, images: images)

        // Act & Assert
        #expect(throws: expected) {
            try item.addingImages([Self.otherImage], policy: policy)
        }
    }

    @Test(
        "画像を消すと、その画像だけがなくなる（完了した家事でも、自分が追加した画像なら無料プランでも消せる）",
        arguments: [
            (HouseworkState.incomplete, HouseworkImagePolicy.premium, "image2", [Self.image]),
            (.completed, .premium, "image2", [Self.image]),
            (.incomplete, .free, "image1", [Self.otherImage]),
        ]
    )
    func removingImage_allowed_removesImage(
        state: HouseworkState,
        policy: HouseworkImagePolicy,
        imageId: String,
        expectedImages: [HouseworkImage]
    ) throws {
        // Arrange
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Self.date,
            state: state,
            images: [Self.image, Self.otherImage]
        )

        // Act
        let actual = try item.removingImage(imageId, policy: policy, userId: "userA")

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, state: state, images: expectedImages)
        #expect(actual == expected)
    }

    @Test("すべての画像を消しても、画像の配列は空のまま残る")
    func removingImage_lastImage_keepsEmptyImages() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])

        // Act
        let actual = try item.removingImage("image1", policy: .premium, userId: "userA")

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [])
        #expect(actual == expected)
    }

    @Test("無料プランでは、同居人が追加した画像は消せない")
    func removingImage_freeAndOthersImage_throws() {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, images: [Self.image, Self.otherImage])

        // Act & Assert
        #expect(throws: HouseworkImageError.notDeletable) {
            try item.removingImage("image2", policy: .free, userId: "userA")
        }
    }

    @Test("見つからない画像を消そうとしたときは、家事を変えない")
    func removingImage_notFound_returnsSelf() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])

        // Act
        let actual = try item.removingImage("unknown", policy: .free, userId: "userB")

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: [Self.image])
        #expect(actual == expected)
    }

    @Test("画像を持たない既存の家事データは、画像なしとして読み込める")
    func decode_withoutImages_returnsNilImages() throws {
        // Arrange
        let json = Data("""
        {
            "id": "id1",
            "indexedDate": { "value": 0 },
            "title": "洗濯",
            "point": 100,
            "state": { "incomplete": {} }
        }
        """.utf8)

        // Act
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: json)

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, title: "洗濯")
        #expect(actual == expected)
    }

    @Test(
        "エンコードしてデコードすると、画像も元に戻る（すべて消した画像は空のまま残る）",
        arguments: [
            [Self.image, Self.otherImage],
            [],
        ]
    )
    func encodeThenDecode_keepsImages(images: [HouseworkImage]) throws {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: images)

        // Act
        let data = try JSONEncoder().encode(item)
        let actual = try JSONDecoder().decode(HouseworkItem.self, from: data)

        // Assert
        let expected = HouseworkItem.makeForTest(id: 1, indexedDate: Self.date, images: images)
        #expect(actual == expected)
    }

    @Test("画像を一度も添えていない家事は、imagesを書き出さない")
    func encode_withoutImages_omitsImagesKey() throws {
        // Arrange
        let item = HouseworkItem.makeForTest(id: 1)

        // Act
        let data = try JSONEncoder().encode(item)

        // Assert
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(object?["images"] == nil)
    }

}
