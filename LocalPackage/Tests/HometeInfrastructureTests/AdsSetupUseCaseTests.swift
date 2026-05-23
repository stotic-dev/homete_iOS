//
//  AdsSetupUseCaseTests.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/23.
//

@testable import HometeInfrastructure
import Testing

struct AdsSetupUseCaseTests {

    @Test("全Clientが成功した場合、MobileAds.initializeが呼ばれる")
    func setup_allSucceed_initializesMobileAds() async {
        // Arrange
        let consentClient = MockConsentClient(canRequestAdsValue: true)
        let appTrackingClient = MockAppTrackingClient()
        let mobileAdsClient = MockMobileAdsClient()
        let sut = AdsSetupUseCase(
            consentClient: consentClient,
            appTrackingClient: appTrackingClient,
            mobileAdsClient: mobileAdsClient
        )

        // Act
        await sut.setup()

        // Assert
        let actual = await TestRecord(
            consent: consentClient.record,
            appTracking: appTrackingClient.record,
            mobileAds: mobileAdsClient.record
        )
        let expected = TestRecord(
            consent: ConsentRecord(
                requestConsentInfoUpdateCount: 1,
                loadAndPresentConsentFormIfRequiredCount: 1,
                canRequestAdsCount: 1
            ),
            appTracking: AppTrackingRecord(requestTrackingAuthorizationCount: 1),
            mobileAds: MobileAdsRecord(initializeCount: 1)
        )
        #expect(actual == expected)
    }

    @Test("同意情報取得が失敗してもATT・MobileAdsの起動シーケンスは継続する")
    func setup_consentInfoUpdateFails_continuesSequence() async {
        // Arrange
        let consentClient = MockConsentClient(
            canRequestAdsValue: true,
            requestConsentInfoUpdateError: MockError.testError
        )
        let appTrackingClient = MockAppTrackingClient()
        let mobileAdsClient = MockMobileAdsClient()
        let sut = AdsSetupUseCase(
            consentClient: consentClient,
            appTrackingClient: appTrackingClient,
            mobileAdsClient: mobileAdsClient
        )

        // Act
        await sut.setup()

        // Assert
        let actual = await TestRecord(
            consent: consentClient.record,
            appTracking: appTrackingClient.record,
            mobileAds: mobileAdsClient.record
        )
        let expected = TestRecord(
            consent: ConsentRecord(
                requestConsentInfoUpdateCount: 1,
                loadAndPresentConsentFormIfRequiredCount: 0,
                canRequestAdsCount: 1
            ),
            appTracking: AppTrackingRecord(requestTrackingAuthorizationCount: 1),
            mobileAds: MobileAdsRecord(initializeCount: 1)
        )
        #expect(actual == expected)
    }

    @Test("canRequestAdsがfalseの場合、MobileAds.initializeは呼ばれない")
    func setup_canRequestAdsIsFalse_doesNotInitializeMobileAds() async {
        // Arrange
        let consentClient = MockConsentClient(canRequestAdsValue: false)
        let appTrackingClient = MockAppTrackingClient()
        let mobileAdsClient = MockMobileAdsClient()
        let sut = AdsSetupUseCase(
            consentClient: consentClient,
            appTrackingClient: appTrackingClient,
            mobileAdsClient: mobileAdsClient
        )

        // Act
        await sut.setup()

        // Assert
        let actual = await TestRecord(
            consent: consentClient.record,
            appTracking: appTrackingClient.record,
            mobileAds: mobileAdsClient.record
        )
        let expected = TestRecord(
            consent: ConsentRecord(
                requestConsentInfoUpdateCount: 1,
                loadAndPresentConsentFormIfRequiredCount: 1,
                canRequestAdsCount: 1
            ),
            appTracking: AppTrackingRecord(requestTrackingAuthorizationCount: 1),
            mobileAds: MobileAdsRecord(initializeCount: 0)
        )
        #expect(actual == expected)
    }

    @Test("呼び出し順序は 同意フォーム → ATT → MobileAds の順")
    func setup_callsInExpectedOrder() async {
        // Arrange
        let log = CallOrderLog()
        let consentClient = MockConsentClient(canRequestAdsValue: true, callOrderLog: log)
        let appTrackingClient = MockAppTrackingClient(callOrderLog: log)
        let mobileAdsClient = MockMobileAdsClient(callOrderLog: log)
        let sut = AdsSetupUseCase(
            consentClient: consentClient,
            appTrackingClient: appTrackingClient,
            mobileAdsClient: mobileAdsClient
        )

        // Act
        await sut.setup()

        // Assert
        let actual = await log.entries
        let expected: [CallOrderLog.Entry] = [
            .consentRequestConsentInfoUpdate,
            .consentLoadAndPresentConsentFormIfRequired,
            .appTrackingRequestTrackingAuthorization,
            .mobileAdsInitialize,
        ]
        #expect(actual == expected)
    }

}

// MARK: - Test Records

private struct TestRecord: Equatable {

    let consent: ConsentRecord
    let appTracking: AppTrackingRecord
    let mobileAds: MobileAdsRecord

}

private struct ConsentRecord: Equatable {

    let requestConsentInfoUpdateCount: Int
    let loadAndPresentConsentFormIfRequiredCount: Int
    let canRequestAdsCount: Int

}

private struct AppTrackingRecord: Equatable {

    let requestTrackingAuthorizationCount: Int

}

private struct MobileAdsRecord: Equatable {

    let initializeCount: Int

}

// MARK: - Mocks

private enum MockError: Error {

    case testError

}

private actor CallOrderLog {

    enum Entry: Equatable {

        case consentRequestConsentInfoUpdate
        case consentLoadAndPresentConsentFormIfRequired
        case appTrackingRequestTrackingAuthorization
        case mobileAdsInitialize

    }

    private(set) var entries: [Entry] = []

    func append(_ entry: Entry) {
        entries.append(entry)
    }

}

private final actor MockConsentClient: ConsentClientProtocol {

    private let canRequestAdsValue: Bool
    private let requestConsentInfoUpdateError: Error?
    private let loadAndPresentConsentFormIfRequiredError: Error?
    private let callOrderLog: CallOrderLog?
    private(set) var record = ConsentRecord(
        requestConsentInfoUpdateCount: 0,
        loadAndPresentConsentFormIfRequiredCount: 0,
        canRequestAdsCount: 0
    )

    init(
        canRequestAdsValue: Bool,
        requestConsentInfoUpdateError: Error? = nil,
        loadAndPresentConsentFormIfRequiredError: Error? = nil,
        callOrderLog: CallOrderLog? = nil
    ) {
        self.canRequestAdsValue = canRequestAdsValue
        self.requestConsentInfoUpdateError = requestConsentInfoUpdateError
        self.loadAndPresentConsentFormIfRequiredError = loadAndPresentConsentFormIfRequiredError
        self.callOrderLog = callOrderLog
    }

    func requestConsentInfoUpdate() async throws {
        record = ConsentRecord(
            requestConsentInfoUpdateCount: record.requestConsentInfoUpdateCount + 1,
            loadAndPresentConsentFormIfRequiredCount: record.loadAndPresentConsentFormIfRequiredCount,
            canRequestAdsCount: record.canRequestAdsCount
        )
        await callOrderLog?.append(.consentRequestConsentInfoUpdate)
        if let error = requestConsentInfoUpdateError {
            throw error
        }
    }

    func loadAndPresentConsentFormIfRequired() async throws {
        record = ConsentRecord(
            requestConsentInfoUpdateCount: record.requestConsentInfoUpdateCount,
            loadAndPresentConsentFormIfRequiredCount: record.loadAndPresentConsentFormIfRequiredCount + 1,
            canRequestAdsCount: record.canRequestAdsCount
        )
        await callOrderLog?.append(.consentLoadAndPresentConsentFormIfRequired)
        if let error = loadAndPresentConsentFormIfRequiredError {
            throw error
        }
    }

    func canRequestAds() async -> Bool {
        record = ConsentRecord(
            requestConsentInfoUpdateCount: record.requestConsentInfoUpdateCount,
            loadAndPresentConsentFormIfRequiredCount: record.loadAndPresentConsentFormIfRequiredCount,
            canRequestAdsCount: record.canRequestAdsCount + 1
        )
        return canRequestAdsValue
    }

}

private final actor MockAppTrackingClient: AppTrackingClientProtocol {

    private let returnStatus: AppTrackingAuthorizationStatus
    private let callOrderLog: CallOrderLog?
    private(set) var record = AppTrackingRecord(requestTrackingAuthorizationCount: 0)

    init(
        returnStatus: AppTrackingAuthorizationStatus = .authorized,
        callOrderLog: CallOrderLog? = nil
    ) {
        self.returnStatus = returnStatus
        self.callOrderLog = callOrderLog
    }

    func requestTrackingAuthorization() async -> AppTrackingAuthorizationStatus {
        record = AppTrackingRecord(
            requestTrackingAuthorizationCount: record.requestTrackingAuthorizationCount + 1
        )
        await callOrderLog?.append(.appTrackingRequestTrackingAuthorization)
        return returnStatus
    }

}

private final actor MockMobileAdsClient: MobileAdsClientProtocol {

    private let callOrderLog: CallOrderLog?
    private(set) var record = MobileAdsRecord(initializeCount: 0)

    init(callOrderLog: CallOrderLog? = nil) {
        self.callOrderLog = callOrderLog
    }

    func initialize() async {
        record = MobileAdsRecord(initializeCount: record.initializeCount + 1)
        await callOrderLog?.append(.mobileAdsInitialize)
    }

}
