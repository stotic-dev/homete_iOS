//
//  AppDependencies.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

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
    public let houseworkTemplateClient: HouseworkTemplateClient

    public init(
        nonceGeneratorClient: NonceGenerationClient = .previewValue,
        accountAuthClient: AccountAuthClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        accountInfoClient: AccountInfoClient = .previewValue,
        cohabitantClient: CohabitantClient = .previewValue,
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        signInWithAppleClient: SignInWithAppleClient = .previewValue,
        houseworkTemplateClient: HouseworkTemplateClient = .previewValue
    ) {
        self.nonceGeneratorClient = nonceGeneratorClient
        self.accountAuthClient = accountAuthClient
        self.analyticsClient = analyticsClient
        self.accountInfoClient = accountInfoClient
        self.cohabitantClient = cohabitantClient
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.signInWithAppleClient = signInWithAppleClient
        self.houseworkTemplateClient = houseworkTemplateClient
    }
}

// MARK: Preview用の定義

extension AppDependencies {

    public static let previewValue: Self = .init()
}

extension EnvironmentValues {

    @Entry public var appDependencies: AppDependencies = .init()
}
