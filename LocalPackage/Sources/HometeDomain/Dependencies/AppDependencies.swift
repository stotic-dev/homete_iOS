//
//  AppDependencies.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

#if canImport(SwiftUI)
import SwiftUI

public struct AppDependencies: Sendable {
    public let nonceGeneratorClient: NonceGenerationClient
    public let accountAuthClient: AccountAuthClient
    public let analyticsClient: AnalyticsClient
    public let accountInfoClient: AccountInfoClient
    public let cohabitantClient: CohabitantClient
    public let houseworkClient: HouseworkClient
    public let cohabitantPushNotificationClient: CohabitantPushNotificationClient
    public let signInWithAppleClient: SignInWithAppleClient

    public init(
        nonceGeneratorClient: NonceGenerationClient = .previewValue,
        accountAuthClient: AccountAuthClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        accountInfoClient: AccountInfoClient = .previewValue,
        cohabitantClient: CohabitantClient = .previewValue,
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        signInWithAppleClient: SignInWithAppleClient = .previewValue
    ) {
        self.nonceGeneratorClient = nonceGeneratorClient
        self.accountAuthClient = accountAuthClient
        self.analyticsClient = analyticsClient
        self.accountInfoClient = accountInfoClient
        self.cohabitantClient = cohabitantClient
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.signInWithAppleClient = signInWithAppleClient
    }
}

// MARK: Preview用の定義

extension AppDependencies {

    public static let previewValue: Self = .init()
}

extension EnvironmentValues {

    @Entry public var appDependencies: AppDependencies = .init()
}
#endif
