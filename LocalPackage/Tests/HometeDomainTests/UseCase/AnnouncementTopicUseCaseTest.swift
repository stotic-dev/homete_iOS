//
//  AnnouncementTopicUseCaseTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct AnnouncementTopicUseCaseTest {

    /// トピックの購読の呼び出し
    enum TopicCall: Equatable {

        case subscribe
        case unsubscribe

    }

    @Test(
        "起動時は保存している設定どおりに、トピックを購読する／やめる",
        arguments: [
            (true, TopicCall.subscribe),
            (false, TopicCall.unsubscribe),
        ]
    )
    func sync_followsSavedSetting(isEnabled: Bool, expected: TopicCall) async {
        // Arrange
        let calls = TestBox(value: [TopicCall]())
        let sut = AnnouncementTopicUseCase(client: .init(
            loadIsEnabled: { isEnabled },
            subscribe: { calls.value.append(.subscribe) },
            unsubscribe: { calls.value.append(.unsubscribe) }
        ))

        // Act
        await sut.sync()

        // Assert
        #expect(calls.value == [expected])
    }

    @Test(
        "設定を変えると保存し、トピックの購読を切り替える",
        arguments: [
            (true, TopicCall.subscribe),
            (false, TopicCall.unsubscribe),
        ]
    )
    func update_savesAndSwitchesTopic(isEnabled: Bool, expected: TopicCall) async {
        // Arrange
        let saved = TestBox(value: [Bool]())
        let calls = TestBox(value: [TopicCall]())
        let sut = AnnouncementTopicUseCase(client: .init(
            saveIsEnabled: { saved.value.append($0) },
            subscribe: { calls.value.append(.subscribe) },
            unsubscribe: { calls.value.append(.unsubscribe) }
        ))

        // Act
        await sut.update(isEnabled: isEnabled)

        // Assert
        #expect(saved.value == [isEnabled])
        #expect(calls.value == [expected])
    }

}
