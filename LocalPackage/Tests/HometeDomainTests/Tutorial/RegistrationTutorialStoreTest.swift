//
//  RegistrationTutorialStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct RegistrationTutorialStoreTest {

    // MARK: restoreIfNeeded

    @Test("見終わっていないチュートリアルが残っていてグループに所属していれば、最初のステップから出し直す")
    func restoreIfNeeded_pendingAndHasCohabitant_startsFromFirstStep() async {
        // Arrange
        let sut = RegistrationTutorialStore(stateClient: .init(loadIsPending: { true }))

        // Act
        await sut.restoreIfNeeded(hasCohabitant: true)

        // Assert
        #expect(sut.currentStep == .dashboard)
    }

    @Test("見終わっていないチュートリアルが残っていても、グループに所属していなければ出さない")
    func restoreIfNeeded_pendingAndNoCohabitant_doesNotStart() async {
        // Arrange
        let sut = RegistrationTutorialStore(stateClient: .init(loadIsPending: { true }))

        // Act
        await sut.restoreIfNeeded(hasCohabitant: false)

        // Assert
        #expect(sut.currentStep == nil)
    }

    @Test("表示中でも、グループに所属していなければ閉じて、見終わっていないことの記録を消す。イベントは送らない")
    func restoreIfNeeded_presentingAndNoCohabitant_dismisses() async {
        // Arrange
        let savedValues = TestLockedArray<Bool>()
        let sut = RegistrationTutorialStore(
            currentStep: .housework,
            stateClient: .init(saveIsPending: { await savedValues.append($0) }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        await sut.restoreIfNeeded(hasCohabitant: false)

        // Assert
        #expect(sut.currentStep == nil)
        #expect(await savedValues.values == [false])
    }

    @Test("見終わっていないチュートリアルが無ければ出さない")
    func restoreIfNeeded_notPending_doesNotStart() async {
        // Arrange
        let sut = RegistrationTutorialStore(stateClient: .init(loadIsPending: { false }))

        // Act
        await sut.restoreIfNeeded(hasCohabitant: true)

        // Assert
        #expect(sut.currentStep == nil)
    }

    @Test("表示中であれば、最初のステップに戻さない")
    func restoreIfNeeded_presenting_keepsCurrentStep() async {
        // Arrange
        let sut = RegistrationTutorialStore(
            currentStep: .thanks,
            stateClient: .init(loadIsPending: { true })
        )

        // Act
        await sut.restoreIfNeeded(hasCohabitant: true)

        // Assert
        #expect(sut.currentStep == .thanks)
    }

    // MARK: didChangeCohabitant

    @Test("未所属からグループに所属したら、見終わっていないことを記録して最初のステップから始める")
    func didChangeCohabitant_fromNilToId_startsAndSavesPending() async {
        // Arrange
        let savedValues = TestLockedArray<Bool>()
        let sut = RegistrationTutorialStore(
            stateClient: .init(saveIsPending: { await savedValues.append($0) })
        )

        // Act
        await sut.didChangeCohabitant(from: nil, to: "cohabitantId")

        // Assert
        #expect(sut.currentStep == .dashboard)
        #expect(await savedValues.values == [true])
    }

    @Test(
        "未所属からの所属でなければ、チュートリアルを始めない",
        arguments: [
            ("old" as String?, "new" as String?),
            ("old" as String?, nil as String?),
            (nil as String?, nil as String?),
        ]
    )
    func didChangeCohabitant_otherTransition_doesNotStart(oldValue: String?, newValue: String?) async {
        // Arrange
        let sut = RegistrationTutorialStore(
            stateClient: .init(saveIsPending: { _ in Issue.record() })
        )

        // Act
        await sut.didChangeCohabitant(from: oldValue, to: newValue)

        // Assert
        #expect(sut.currentStep == nil)
    }

    @Test("表示中にグループを抜けたら閉じて、見終わっていないことの記録を消す。イベントは送らない")
    func didChangeCohabitant_fromIdToNilWhilePresenting_dismisses() async {
        // Arrange
        let savedValues = TestLockedArray<Bool>()
        let sut = RegistrationTutorialStore(
            currentStep: .thanks,
            stateClient: .init(saveIsPending: { await savedValues.append($0) }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        await sut.didChangeCohabitant(from: "cohabitantId", to: nil)

        // Assert
        #expect(sut.currentStep == nil)
        #expect(await savedValues.values == [false])
    }

    // MARK: next

    @Test(
        "最後以外のステップでは、次のステップへ進める",
        arguments: [
            (RegistrationTutorialStep.dashboard, RegistrationTutorialStep.housework),
            (.housework, .thanks),
            (.thanks, .houseworkTemplate),
        ]
    )
    func next_notLastStep_movesToNextStep(
        currentStep: RegistrationTutorialStep,
        expected: RegistrationTutorialStep
    ) async {
        // Arrange
        let sut = RegistrationTutorialStore(
            currentStep: currentStep,
            stateClient: .init(saveIsPending: { _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        await sut.next(from: currentStep)

        // Assert
        #expect(sut.currentStep == expected)
    }

    @Test("最後のステップでは、チュートリアルを終えて見終わったことを記録し、完了のイベントを送る")
    func next_lastStep_finishes() async {
        // Arrange
        let savedValues = TestLockedArray<Bool>()
        let loggedEvents = TestBox<[AnalyticsEvent]>(value: [])
        let sut = RegistrationTutorialStore(
            currentStep: .houseworkTemplate,
            stateClient: .init(saveIsPending: { await savedValues.append($0) }),
            analyticsClient: .init(log: { loggedEvents.value.append($0) })
        )

        // Act
        await sut.next(from: .houseworkTemplate)

        // Assert
        #expect(sut.currentStep == nil)
        #expect(await savedValues.values == [false])
        #expect(loggedEvents.value == [.registrationTutorial(.completed)])
    }

    @Test("表示中のステップと違うステップから進めようとしたら、何もしない")
    func next_fromStaleStep_doesNothing() async {
        // Arrange
        let sut = RegistrationTutorialStore(
            currentStep: .thanks,
            stateClient: .init(saveIsPending: { _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        await sut.next(from: .housework)

        // Assert
        #expect(sut.currentStep == .thanks)
    }

    // MARK: back

    @Test(
        "最初以外のステップでは、前のステップへ戻す",
        arguments: [
            (RegistrationTutorialStep.housework, RegistrationTutorialStep.dashboard),
            (.thanks, .housework),
            (.houseworkTemplate, .thanks),
        ]
    )
    func back_notFirstStep_movesToPreviousStep(
        currentStep: RegistrationTutorialStep,
        expected: RegistrationTutorialStep
    ) {
        // Arrange
        let sut = RegistrationTutorialStore(
            currentStep: currentStep,
            stateClient: .init(saveIsPending: { _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        sut.back(from: currentStep)

        // Assert
        #expect(sut.currentStep == expected)
    }

    @Test("最初のステップでは、戻さない")
    func back_firstStep_keepsCurrentStep() {
        // Arrange
        let sut = RegistrationTutorialStore(
            currentStep: .dashboard,
            stateClient: .init(saveIsPending: { _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        sut.back(from: .dashboard)

        // Assert
        #expect(sut.currentStep == .dashboard)
    }

    @Test("表示中のステップと違うステップから戻そうとしたら、何もしない")
    func back_fromStaleStep_doesNothing() {
        // Arrange
        let sut = RegistrationTutorialStore(
            currentStep: .housework,
            stateClient: .init(saveIsPending: { _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        sut.back(from: .thanks)

        // Assert
        #expect(sut.currentStep == .housework)
    }

    // MARK: close

    @Test("途中で閉じると、チュートリアルを終えて見終わったことを記録し、閉じたステップを付けてイベントを送る")
    func close_presenting_finishesWithSkippedEvent() async {
        // Arrange
        let savedValues = TestLockedArray<Bool>()
        let loggedEvents = TestBox<[AnalyticsEvent]>(value: [])
        let sut = RegistrationTutorialStore(
            currentStep: .thanks,
            stateClient: .init(saveIsPending: { await savedValues.append($0) }),
            analyticsClient: .init(log: { loggedEvents.value.append($0) })
        )

        // Act
        await sut.close()

        // Assert
        #expect(sut.currentStep == nil)
        #expect(await savedValues.values == [false])
        #expect(loggedEvents.value == [.registrationTutorial(.skipped(step: .thanks))])
    }

    @Test("表示していなければ、閉じても何もしない")
    func close_notPresenting_doesNothing() async {
        // Arrange
        let sut = RegistrationTutorialStore(
            stateClient: .init(saveIsPending: { _ in Issue.record() }),
            analyticsClient: .init(log: { _ in Issue.record() })
        )

        // Act
        await sut.close()

        // Assert
        #expect(sut.currentStep == nil)
    }

}
