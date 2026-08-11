//
//  NotificationPermissionUseCaseTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct NotificationPermissionUseCaseTest {

    @Test("権限が許可された場合、リモート通知の登録まで行う")
    func request_authorizationGranted_registersForRemoteNotifications() async {
        // Arrange

        let recorder = CallRecorder()
        let sut = NotificationPermissionUseCase(
            notificationPermissionClient: makeClient(recorder: recorder, isGranted: true)
        )
        let expected = CallSnapshot(
            entries: [.requestAuthorization, .registerForRemoteNotifications],
            result: true
        )

        // Act

        let isGranted = await sut.request()

        // Assert

        let actual = await CallSnapshot(entries: recorder.entries, result: isGranted)
        #expect(actual == expected)
    }

    @Test("権限が拒否された場合、リモート通知の登録は行わない")
    func request_authorizationDenied_doesNotRegisterForRemoteNotifications() async {
        // Arrange

        let recorder = CallRecorder()
        let sut = NotificationPermissionUseCase(
            notificationPermissionClient: makeClient(recorder: recorder, isGranted: false)
        )
        let expected = CallSnapshot(
            entries: [.requestAuthorization],
            result: false
        )

        // Act

        let isGranted = await sut.request()

        // Assert

        let actual = await CallSnapshot(entries: recorder.entries, result: isGranted)
        #expect(actual == expected)
    }

}

// MARK: - Helpers

private struct CallSnapshot: Equatable {

    let entries: [CallRecorder.Entry]
    let result: Bool

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

private func makeClient(recorder: CallRecorder, isGranted: Bool) -> NotificationPermissionClient {
    NotificationPermissionClient(
        requestAuthorization: {
            await recorder.append(.requestAuthorization)
            return isGranted
        },
        registerForRemoteNotifications: {
            await recorder.append(.registerForRemoteNotifications)
        }
    )
}
