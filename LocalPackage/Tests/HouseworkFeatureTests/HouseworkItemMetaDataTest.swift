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

        let actual = HouseworkItemMetaData.make(item: item)

        // Assert

        #expect(actual == nil)
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

        let actual = HouseworkItemMetaData.make(item: item)

        // Assert

        #expect(actual == expected)
    }

    @Test("ありがとうが届いた完了済みの家事は、ありがとうが届いたことを示すメタデータになる")
    func make_completedWithThanks_returnsThanked() {
        // Arrange

        let item = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "otherUserId",
            thanks: [.init(senderId: "sender", comment: "ありがとう", sentAt: .distantPast)]
        )

        // Act

        let actual = HouseworkItemMetaData.make(item: item)

        // Assert

        #expect(actual == .thanked)
    }

    @Test("やらないにした家事は、ありがとうが残っていてもやらないを示すメタデータになる")
    func make_notTodoWithThanks_returnsNotTodo() {
        // Arrange

        let item = HouseworkItem.makeForTest(
            id: 1,
            state: .notTodo,
            executorId: "otherUserId",
            thanks: [.init(senderId: "sender", comment: "ありがとう", sentAt: .distantPast)]
        )

        // Act

        let actual = HouseworkItemMetaData.make(item: item)

        // Assert

        #expect(actual == .notTodo)
    }

}
