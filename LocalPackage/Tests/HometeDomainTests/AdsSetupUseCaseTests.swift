//
//  AdsSetupUseCaseTests.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/23.
//

@testable import HometeDomain
import Testing

struct AdsSetupUseCaseTests {

    @Test("全Clientが成功した場合、MobileAdsClient.initializeが呼ばれる")
    func setup_allSucceed_initializesMobileAds() async {
        // Arrange
        let recorder = CallRecorder()
        let sut = AdsSetupUseCase(
            consentClient: makeConsentClient(recorder: recorder, canRequestAdsValue: true),
            mobileAdsClient: makeMobileAdsClient(recorder: recorder)
        )

        // Act
        await sut.setup()

        // Assert
        let actual = await recorder.snapshot
        let expected = CallSnapshot(
            requestConsentInfoUpdateCount: 1,
            loadAndPresentConsentFormIfRequiredCount: 1,
            canRequestAdsCount: 1,
            initializeCount: 1
        )
        #expect(actual == expected)
    }

    @Test("同意情報取得が失敗してもMobileAdsの起動シーケンスは継続する")
    func setup_consentInfoUpdateFails_continuesSequence() async {
        // Arrange
        let recorder = CallRecorder()
        let sut = AdsSetupUseCase(
            consentClient: makeConsentClient(
                recorder: recorder,
                canRequestAdsValue: true,
                requestConsentInfoUpdateError: MockError.testError
            ),
            mobileAdsClient: makeMobileAdsClient(recorder: recorder)
        )

        // Act
        await sut.setup()

        // Assert
        let actual = await recorder.snapshot
        let expected = CallSnapshot(
            requestConsentInfoUpdateCount: 1,
            loadAndPresentConsentFormIfRequiredCount: 0,
            canRequestAdsCount: 1,
            initializeCount: 1
        )
        #expect(actual == expected)
    }

    @Test("canRequestAdsがfalseの場合、MobileAdsClient.initializeは呼ばれない")
    func setup_canRequestAdsIsFalse_doesNotInitializeMobileAds() async {
        // Arrange
        let recorder = CallRecorder()
        let sut = AdsSetupUseCase(
            consentClient: makeConsentClient(recorder: recorder, canRequestAdsValue: false),
            mobileAdsClient: makeMobileAdsClient(recorder: recorder)
        )

        // Act
        await sut.setup()

        // Assert
        let actual = await recorder.snapshot
        let expected = CallSnapshot(
            requestConsentInfoUpdateCount: 1,
            loadAndPresentConsentFormIfRequiredCount: 1,
            canRequestAdsCount: 1,
            initializeCount: 0
        )
        #expect(actual == expected)
    }

    /// ATT許可リクエストはAdMobコンソールのApp Tracking Transparencyメッセージ設定により
    /// ConsentForm.loadAndPresentIfRequired内で提示されるため、コード上での明示呼び出しはない
    @Test("呼び出し順序は 同意フォーム → MobileAds の順")
    func setup_callsInExpectedOrder() async {
        // Arrange
        let recorder = CallRecorder()
        let sut = AdsSetupUseCase(
            consentClient: makeConsentClient(recorder: recorder, canRequestAdsValue: true),
            mobileAdsClient: makeMobileAdsClient(recorder: recorder)
        )

        // Act
        await sut.setup()

        // Assert
        let actual = await recorder.entries
        let expected: [CallRecorder.Entry] = [
            .consentRequestConsentInfoUpdate,
            .consentLoadAndPresentConsentFormIfRequired,
            .consentCanRequestAds,
            .mobileAdsInitialize,
        ]
        #expect(actual == expected)
    }

}

// MARK: - Helpers

private enum MockError: Error {

    case testError

}

private struct CallSnapshot: Equatable {

    let requestConsentInfoUpdateCount: Int
    let loadAndPresentConsentFormIfRequiredCount: Int
    let canRequestAdsCount: Int
    let initializeCount: Int

}

private actor CallRecorder {

    enum Entry: Equatable {

        case consentRequestConsentInfoUpdate
        case consentLoadAndPresentConsentFormIfRequired
        case consentCanRequestAds
        case mobileAdsInitialize

    }

    private(set) var entries: [Entry] = []

    var snapshot: CallSnapshot {
        CallSnapshot(
            requestConsentInfoUpdateCount: entries.filter { $0 == .consentRequestConsentInfoUpdate }.count,
            loadAndPresentConsentFormIfRequiredCount: entries.filter {
                $0 == .consentLoadAndPresentConsentFormIfRequired
            }.count,
            canRequestAdsCount: entries.filter { $0 == .consentCanRequestAds }.count,
            initializeCount: entries.filter { $0 == .mobileAdsInitialize }.count
        )
    }

    func append(_ entry: Entry) {
        entries.append(entry)
    }

}

private func makeConsentClient(
    recorder: CallRecorder,
    canRequestAdsValue: Bool,
    requestConsentInfoUpdateError: Error? = nil,
    loadAndPresentConsentFormIfRequiredError: Error? = nil
) -> ConsentClient {
    ConsentClient(
        requestConsentInfoUpdate: {
            await recorder.append(.consentRequestConsentInfoUpdate)
            if let error = requestConsentInfoUpdateError {
                throw error
            }
        },
        loadAndPresentConsentFormIfRequired: {
            await recorder.append(.consentLoadAndPresentConsentFormIfRequired)
            if let error = loadAndPresentConsentFormIfRequiredError {
                throw error
            }
        },
        canRequestAds: {
            await recorder.append(.consentCanRequestAds)
            return canRequestAdsValue
        }
    )
}

private func makeMobileAdsClient(recorder: CallRecorder) -> MobileAdsClient {
    MobileAdsClient(
        initialize: {
            await recorder.append(.mobileAdsInitialize)
        }
    )
}
