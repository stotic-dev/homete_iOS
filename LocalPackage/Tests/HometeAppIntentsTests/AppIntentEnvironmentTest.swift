//
//  AppIntentEnvironmentTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeAppIntents
import HometeDomain
import Testing

/// Intentの処理を実行し、結果を`app_intent`イベントで送る
struct AppIntentEnvironmentTest {

    private struct UserCancelled: Error, Equatable {}

    @Test("実行できなかった理由がAppIntentFailureなら、その結果でイベントを送り、ユーザーに伝える文言に変えて投げる")
    func perform_appIntentFailure() async {
        // Arrange

        await confirmation { confirmation in
            let sut = makeSUT(log: { event in
                // Assert

                #expect(event == .appIntent(.completeHousework, result: .noCohabitant))
                confirmation()
            })

            // Act

            await #expect(throws: AppIntentMessageError.self) {
                try await sut.perform(.completeHousework) { () async throws in
                    throw AppIntentFailure.noCohabitant
                }
            }
        }
    }

    @Test("聞き返しをユーザーが選ばずに閉じたときは、イベントを送らずに元のエラーを投げる")
    func perform_userInteractionInterrupted() async {
        // Arrange

        let sut = makeSUT(log: { _ in Issue.record("イベントを送らない") })

        // Act

        await #expect(throws: UserCancelled()) {
            try await sut.perform(.sendThanks) { () async throws in
                throw AppIntentUserInteractionInterrupted(underlyingError: UserCancelled())
            }
        }
    }

}

private extension AppIntentEnvironmentTest {

    func makeSUT(log: @escaping @Sendable (AnalyticsEvent) -> Void) -> AppIntentEnvironment {
        .init(
            dependencies: .init(analyticsClient: .init(log: log)),
            currentAppVersion: "1.0.0",
            calendar: .japanese
        )
    }

}
