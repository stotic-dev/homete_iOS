//
//  HouseworkItemMetaDataTest.swift
//  LocalPackage
//

@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct HouseworkItemMetaDataTest {

    @Test("未完了の家事は補うメタデータがない")
    func make_incomplete_returnsNil() {
        // Arrange

        let item = HouseworkItem.makeForTest(id: 1, state: .incomplete)

        // Act

        let actual = HouseworkItemMetaData.make(item: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == nil)
    }

    @Test("承認待ちで相手が実施した家事は、自分の確認が必要なメタデータになる")
    func make_pendingApprovalByOtherUser_returnsNeedsOwnReview() {
        // Arrange

        let item = HouseworkItem.makeForTest(id: 1, state: .pendingApproval, executorId: "otherUserId")

        // Act

        let actual = HouseworkItemMetaData.make(item: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == .needsOwnReview)
    }

    @Test("承認待ちで自分が実施した家事は、相手の確認待ちのメタデータになる")
    func make_pendingApprovalByOwnUser_returnsWaitingForOtherReview() {
        // Arrange

        let item = HouseworkItem.makeForTest(id: 1, state: .pendingApproval, executorId: "ownUserId")

        // Act

        let actual = HouseworkItemMetaData.make(item: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == .waitingForOtherReview)
    }

    @Test(
        "完了・やらないの家事はステータスをそのまま示すメタデータになる",
        arguments: [
            (HouseworkState.completed, HouseworkItemMetaData.completed),
            (.notTodo, .notTodo),
        ]
    )
    func make_settledStates_returnsMatchingMetaData(state: HouseworkState, expected: HouseworkItemMetaData) {
        // Arrange

        let item = HouseworkItem.makeForTest(id: 1, state: state, executorId: "otherUserId")

        // Act

        let actual = HouseworkItemMetaData.make(item: item, ownUserId: "ownUserId")

        // Assert

        #expect(actual == expected)
    }

}
