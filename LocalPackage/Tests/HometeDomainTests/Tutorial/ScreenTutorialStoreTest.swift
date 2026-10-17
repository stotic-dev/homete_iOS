//
//  ScreenTutorialStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct ScreenTutorialStoreTest {

    // MARK: startIfNeeded

    @Test("まだ見ていなければ、最初のステップから出す")
    func startIfNeeded_notSeen_startsFromFirstStep() async {
        // Arrange
        let loadedScreens = TestLockedArray<ScreenTutorial>()
        let sut = ScreenTutorialStore<RegisterHouseworkTutorialStep>(
            stateClient: .init(loadHasSeen: { screen in
                await loadedScreens.append(screen)
                return false
            })
        )

        // Act
        await sut.startIfNeeded()

        // Assert
        #expect(sut.currentStep == .inputSource)
        #expect(await loadedScreens.values == [.registerHousework])
    }

    @Test("見たことがあれば出さない")
    func startIfNeeded_seen_doesNotStart() async {
        // Arrange
        let sut = ScreenTutorialStore<RegisterHouseworkTutorialStep>(
            stateClient: .init(loadHasSeen: { _ in true })
        )

        // Act
        await sut.startIfNeeded()

        // Assert
        #expect(sut.currentStep == nil)
    }

    @Test("表示中であれば、最初のステップに戻さない")
    func startIfNeeded_presenting_keepsCurrentStep() async {
        // Arrange
        let sut = ScreenTutorialStore<RegisterHouseworkTutorialStep>(
            currentStep: .queue,
            stateClient: .init(loadHasSeen: { _ in false })
        )

        // Act
        await sut.startIfNeeded()

        // Assert
        #expect(sut.currentStep == .queue)
    }

    // MARK: next

    @Test(
        "最後以外のステップでは、次のステップへ進める",
        arguments: [
            (RegisterHouseworkTutorialStep.inputSource, RegisterHouseworkTutorialStep.queue),
            (.queue, .saveAsFrequent),
        ]
    )
    func next_notLastStep_movesToNextStep(
        currentStep: RegisterHouseworkTutorialStep,
        expected: RegisterHouseworkTutorialStep
    ) async {
        // Arrange
        let sut = ScreenTutorialStore(
            currentStep: currentStep,
            stateClient: .init(saveHasSeen: { _, _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        await sut.next(from: currentStep)

        // Assert
        #expect(sut.currentStep == expected)
    }

    @Test("最後のステップでは、チュートリアルを終えてその画面のチュートリアルを見たと記録し、完了のイベントを送る")
    func next_lastStep_finishes() async {
        // Arrange
        let savedStates = TestLockedArray<SavedState>()
        let loggedEvents = TestBox<[AnalyticsEvent]>(value: [])
        let sut = ScreenTutorialStore(
            currentStep: HouseworkTemplateTutorialStep.save,
            stateClient: .init(saveHasSeen: { await savedStates.append(.init(screen: $0, hasSeen: $1)) }),
            analyticsClient: .init(log: { loggedEvents.value.append($0) })
        )

        // Act
        await sut.next(from: .save)

        // Assert
        #expect(sut.currentStep == nil)
        #expect(await savedStates.values == [.init(screen: .houseworkTemplate, hasSeen: true)])
        #expect(loggedEvents.value == [.screenTutorial(.completed(screen: .houseworkTemplate))])
    }

    @Test("表示中のステップと違うステップから進めようとしたら、何もしない")
    func next_fromStaleStep_doesNothing() async {
        // Arrange
        let sut = ScreenTutorialStore(
            currentStep: RegisterHouseworkTutorialStep.queue,
            stateClient: .init(saveHasSeen: { _, _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        await sut.next(from: .inputSource)

        // Assert
        #expect(sut.currentStep == .queue)
    }

    // MARK: back

    @Test(
        "最初以外のステップでは、前のステップへ戻す",
        arguments: [
            (HouseworkTemplateTutorialStep.addItem, HouseworkTemplateTutorialStep.create),
            (.autoPlacement, .addItem),
            (.save, .autoPlacement),
        ]
    )
    func back_notFirstStep_movesToPreviousStep(
        currentStep: HouseworkTemplateTutorialStep,
        expected: HouseworkTemplateTutorialStep
    ) {
        // Arrange
        let sut = ScreenTutorialStore(currentStep: currentStep)

        // Act
        sut.back(from: currentStep)

        // Assert
        #expect(sut.currentStep == expected)
    }

    @Test("最初のステップでは、何もしない")
    func back_firstStep_doesNothing() {
        // Arrange
        let sut = ScreenTutorialStore(currentStep: HouseworkTemplateTutorialStep.create)

        // Act
        sut.back(from: .create)

        // Assert
        #expect(sut.currentStep == .create)
    }

    @Test("表示中のステップと違うステップから戻そうとしたら、何もしない")
    func back_fromStaleStep_doesNothing() {
        // Arrange
        let sut = ScreenTutorialStore(currentStep: HouseworkTemplateTutorialStep.addItem)

        // Act
        sut.back(from: .save)

        // Assert
        #expect(sut.currentStep == .addItem)
    }

    // MARK: close

    @Test("途中で閉じたら、チュートリアルを終えてその画面のチュートリアルを見たと記録し、閉じたステップを載せたイベントを送る")
    func close_presenting_finishes() async {
        // Arrange
        let savedStates = TestLockedArray<SavedState>()
        let loggedEvents = TestBox<[AnalyticsEvent]>(value: [])
        let sut = ScreenTutorialStore(
            currentStep: RegisterHouseworkTutorialStep.queue,
            stateClient: .init(saveHasSeen: { await savedStates.append(.init(screen: $0, hasSeen: $1)) }),
            analyticsClient: .init(log: { loggedEvents.value.append($0) })
        )

        // Act
        await sut.close()

        // Assert
        #expect(sut.currentStep == nil)
        #expect(await savedStates.values == [.init(screen: .registerHousework, hasSeen: true)])
        #expect(loggedEvents.value == [.screenTutorial(.skipped(screen: .registerHousework, step: "queue"))])
    }

    @Test("表示していなければ、記録もイベントの送信もしない")
    func close_notPresenting_doesNothing() async {
        // Arrange
        let sut = ScreenTutorialStore<RegisterHouseworkTutorialStep>(
            stateClient: .init(saveHasSeen: { _, _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        await sut.close()

        // Assert
        #expect(sut.currentStep == nil)
    }

}

private struct SavedState: Equatable {

    let screen: ScreenTutorial
    let hasSeen: Bool

}
