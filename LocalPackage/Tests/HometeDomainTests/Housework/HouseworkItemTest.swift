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
