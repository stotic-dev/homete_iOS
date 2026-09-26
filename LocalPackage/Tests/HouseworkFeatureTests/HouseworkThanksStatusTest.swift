//
//  HouseworkThanksStatusTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct HouseworkThanksStatusTest {

    @Test("自分以外が終えた家事に、まだありがとうを送っていない場合は未送信になる")
    func make_completedByOtherUserNotSent_returnsNotSent() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId",
            thanks: ["anotherUserId": .init(comment: nil, sentAt: .distantPast)]
        )

        // Act
        let result = HouseworkThanksStatus.make(item: item, ownUserId: "ownUserId")

        // Assert
        #expect(result == .notSent)
    }

    @Test("自分以外が終えた家事に、ありがとうを送った場合は送信済みになる")
    func make_completedByOtherUserSent_returnsSent() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "otherUserId",
            thanks: ["ownUserId": .init(comment: "ありがとう", sentAt: .distantPast)]
        )

        // Act
        let result = HouseworkThanksStatus.make(item: item, ownUserId: "ownUserId")

        // Assert
        #expect(result == .sent)
    }

    @Test("自分が終えた家事に、ありがとうが届いた場合は受け取りになる")
    func make_completedByOwnUserReceived_returnsReceived() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "ownUserId",
            thanks: ["otherUserId": .init(comment: nil, sentAt: .distantPast)]
        )

        // Act
        let result = HouseworkThanksStatus.make(item: item, ownUserId: "ownUserId")

        // Assert
        #expect(result == .received)
    }

    @Test("自分が終えた家事に、まだ誰からもありがとうが届いていない場合は何も出さない")
    func make_completedByOwnUserNotReceived_returnsNil() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "ownUserId"
        )

        // Act
        let result = HouseworkThanksStatus.make(item: item, ownUserId: "ownUserId")

        // Assert
        #expect(result == nil)
    }

    @Test(
        "完了していない家事には、ありがとうの状況を出さない",
        arguments: [HouseworkState.incomplete, .notTodo]
    )
    func make_notCompleted_returnsNil(state: HouseworkState) {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: state,
            executorId: "otherUserId"
        )

        // Act
        let result = HouseworkThanksStatus.make(item: item, ownUserId: "ownUserId")

        // Assert
        #expect(result == nil)
    }

}
