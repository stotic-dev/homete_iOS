//
//  AppDependencies+liveValue.swift
//

import HometeDomain

// MARK: Live用の定義

extension AppDependencies {

    public static let liveValue: Self = .init(
        nonceGeneratorClient: .liveValue,
        accountAuthClient: .liveValue,
        analyticsClient: .liveValue,
        accountInfoClient: .liveValue,
        cohabitantClient: .liveValue,
        houseworkClient: .liveValue,
        cohabitantPushNotificationClient: .liveValue,
        signInWithAppleClient: .liveValue,
        houseworkTemplateClient: .liveValue
    )
}
