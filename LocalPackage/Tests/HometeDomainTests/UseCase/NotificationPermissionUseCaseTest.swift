//
//  NotificationPermissionUseCaseTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct NotificationPermissionUseCaseTest {

    @Test("通知の権限が未決定の場合は、オンボーディングで通知の案内を行う")
    func shouldGuideOnOnboarding_authorizationNotDetermined_returnsTrue() async {
        // Arrange
        let recorder = CallRecorder()
        let guideState = GuideStateStore()
        let sut = makeSUT(recorder: recorder, guideState: guideState, isGranted: true)
        let expected = CallSnapshot(entries: [], hasGuidedOnOnboarding: false, result: true)

        // Act

        let shouldGuide = await sut.shouldGuideOnOnboarding()

        // Assert

        let actual = await CallSnapshot(recorder: recorder, guideState: guideState, result: shouldGuide)
        #expect(actual == expected)
    }

    @Test("通知の権限が決定済みの場合は、オンボーディングで通知の案内を行わない")
    func shouldGuideOnOnboarding_authorizationDetermined_returnsFalse() async {
        // Arrange
        let recorder = CallRecorder()
        let guideState = GuideStateStore()
        let sut = makeSUT(
            recorder: recorder,
            guideState: guideState,
            isGranted: true,
            isAuthorizationDetermined: true
        )
        let expected = CallSnapshot(entries: [], hasGuidedOnOnboarding: false, result: false)

        // Act

        let shouldGuide = await sut.shouldGuideOnOnboarding()

        // Assert

        let actual = await CallSnapshot(recorder: recorder, guideState: guideState, result: shouldGuide)
        #expect(actual == expected)
    }

    @Test("権限が許可された場合、リモート通知の登録まで行う")
    func requestOnOnboarding_authorizationGranted_registersForRemoteNotifications() async {
        // Arrange
        let recorder = CallRecorder()
        let guideState = GuideStateStore()
        let sut = makeSUT(recorder: recorder, guideState: guideState, isGranted: true)
        let expected = CallSnapshot(
            entries: [.requestAuthorization, .registerForRemoteNotifications],
            hasGuidedOnOnboarding: true,
            result: true
        )

        // Act

        let isGranted = await sut.requestOnOnboarding()

        // Assert

        let actual = await CallSnapshot(recorder: recorder, guideState: guideState, result: isGranted)
        #expect(actual == expected)
    }

    @Test("権限が拒否された場合、リモート通知の登録は行わない")
    func requestOnOnboarding_authorizationDenied_doesNotRegisterForRemoteNotifications() async {
        // Arrange
        let recorder = CallRecorder()
        let guideState = GuideStateStore()
        let sut = makeSUT(recorder: recorder, guideState: guideState, isGranted: false)
        let expected = CallSnapshot(
            entries: [.requestAuthorization],
            hasGuidedOnOnboarding: true,
            result: false
        )

        // Act

        let isGranted = await sut.requestOnOnboarding()

        // Assert

        let actual = await CallSnapshot(recorder: recorder, guideState: guideState, result: isGranted)
        #expect(actual == expected)
    }

    @Test("オンボーディングで案内していない場合は、権限をリクエストする")
    func requestIfNeeded_notGuidedOnOnboarding_requestsAuthorization() async {
        // Arrange
        let recorder = CallRecorder()
        let guideState = GuideStateStore()
        let sut = makeSUT(recorder: recorder, guideState: guideState, isGranted: true)
        let expected = CallSnapshot(
            entries: [.requestAuthorization, .registerForRemoteNotifications],
            hasGuidedOnOnboarding: false,
            result: nil
        )

        // Act

        await sut.requestIfNeeded()

        // Assert

        let actual = await CallSnapshot(recorder: recorder, guideState: guideState, result: nil)
        #expect(actual == expected)
    }

    @Test("オンボーディングでスキップされた場合は、権限をリクエストしない")
    func requestIfNeeded_skippedOnOnboarding_doesNotRequestAuthorization() async {
        // Arrange
        let recorder = CallRecorder()
        let guideState = GuideStateStore()
        let sut = makeSUT(recorder: recorder, guideState: guideState, isGranted: true)
        await sut.skipOnOnboarding()
        let expected = CallSnapshot(entries: [], hasGuidedOnOnboarding: true, result: nil)

        // Act

        await sut.requestIfNeeded()

        // Assert

        let actual = await CallSnapshot(recorder: recorder, guideState: guideState, result: nil)
        #expect(actual == expected)
    }

    @Test("オンボーディングで権限をリクエスト済みの場合は、ホーム着地時に再度リクエストしない")
    func requestIfNeeded_alreadyRequestedOnOnboarding_doesNotRequestAgain() async {
        // Arrange
        let recorder = CallRecorder()
        let guideState = GuideStateStore()
        let sut = makeSUT(recorder: recorder, guideState: guideState, isGranted: false)
        await sut.requestOnOnboarding()
        let expected = CallSnapshot(
            entries: [.requestAuthorization],
            hasGuidedOnOnboarding: true,
            result: nil
        )

        // Act

        await sut.requestIfNeeded()

        // Assert

        let actual = await CallSnapshot(recorder: recorder, guideState: guideState, result: nil)
        #expect(actual == expected)
    }

    @Test("前回起動までに案内済みの場合は、起動し直しても権限をリクエストしない")
    func requestIfNeeded_guidedOnPreviousLaunch_doesNotRequestAuthorization() async {
        // Arrange
        let recorder = CallRecorder()
        // 前回起動でのスキップが永続化されている状態を、UseCaseを作り直して再現する
        let guideState = GuideStateStore(hasGuidedOnOnboarding: true)
        let sut = makeSUT(recorder: recorder, guideState: guideState, isGranted: true)
        let expected = CallSnapshot(entries: [], hasGuidedOnOnboarding: true, result: nil)

        // Act

        await sut.requestIfNeeded()

        // Assert

        let actual = await CallSnapshot(recorder: recorder, guideState: guideState, result: nil)
        #expect(actual == expected)
    }

}

// MARK: - Helpers

private struct CallSnapshot: Equatable {

    let entries: [CallRecorder.Entry]
    let hasGuidedOnOnboarding: Bool
    let result: Bool?

    init(entries: [CallRecorder.Entry], hasGuidedOnOnboarding: Bool, result: Bool?) {
        self.entries = entries
        self.hasGuidedOnOnboarding = hasGuidedOnOnboarding
        self.result = result
    }

    init(recorder: CallRecorder, guideState: GuideStateStore, result: Bool?) async {
        entries = await recorder.entries
        hasGuidedOnOnboarding = await guideState.hasGuidedOnOnboarding
        self.result = result
    }

}

private actor CallRecorder {

    enum Entry: Equatable {

        case requestAuthorization
        case registerForRemoteNotifications

    }

    private(set) var entries: [Entry] = []

    func append(_ entry: Entry) {
        entries.append(entry)
    }

}

private actor GuideStateStore {

    private(set) var hasGuidedOnOnboarding: Bool

    init(hasGuidedOnOnboarding: Bool = false) {
        self.hasGuidedOnOnboarding = hasGuidedOnOnboarding
    }

    func save(_ hasGuidedOnOnboarding: Bool) {
        self.hasGuidedOnOnboarding = hasGuidedOnOnboarding
    }

}

private func makeSUT(
    recorder: CallRecorder,
    guideState: GuideStateStore,
    isGranted: Bool,
    isAuthorizationDetermined: Bool = false
) -> NotificationPermissionUseCase {
    NotificationPermissionUseCase(
        notificationPermissionClient: NotificationPermissionClient(
            requestAuthorization: {
                await recorder.append(.requestAuthorization)
                return isGranted
            },
            registerForRemoteNotifications: {
                await recorder.append(.registerForRemoteNotifications)
            },
            isAuthorizationDetermined: { isAuthorizationDetermined }
        ),
        notificationGuideStateClient: NotificationGuideStateClient(
            loadHasGuidedOnOnboarding: { await guideState.hasGuidedOnOnboarding },
            saveHasGuidedOnOnboarding: { await guideState.save($0) }
        )
    )
}
