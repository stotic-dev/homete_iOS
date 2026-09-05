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
    public let cohabitantInvitationClient: CohabitantInvitationClient
    public let houseworkClient: HouseworkClient
    public let cohabitantPushNotificationClient: CohabitantPushNotificationClient
    public let signInWithAppleClient: SignInWithAppleClient
    public let purchaseClient: PurchaseClient
    public let houseworkTemplateClient: HouseworkTemplateClient
    public let consentClient: ConsentClient
    public let mobileAdsClient: MobileAdsClient
    public let notificationPermissionClient: NotificationPermissionClient
    public let notificationGuideStateClient: NotificationGuideStateClient
    public let houseworkManager: HouseworkManager
    /// 広告の同意取得（ATT含む）とMobileAdsの初期化を行うUseCase
    public let adsSetupUseCase: AdsSetupUseCase
    /// プッシュ通知の権限リクエストを行うUseCase
    public let notificationPermissionUseCase: NotificationPermissionUseCase

    public init(
        nonceGeneratorClient: NonceGenerationClient = .previewValue,
        accountAuthClient: AccountAuthClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        accountInfoClient: AccountInfoClient = .previewValue,
        cohabitantClient: CohabitantClient = .previewValue,
        cohabitantInvitationClient: CohabitantInvitationClient = .previewValue,
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        signInWithAppleClient: SignInWithAppleClient = .previewValue,
        purchaseClient: PurchaseClient = .previewValue,
        houseworkTemplateClient: HouseworkTemplateClient = .previewValue,
        consentClient: ConsentClient = .previewValue,
        mobileAdsClient: MobileAdsClient = .previewValue,
        notificationPermissionClient: NotificationPermissionClient = .previewValue,
        notificationGuideStateClient: NotificationGuideStateClient = .previewValue
    ) {
        self.nonceGeneratorClient = nonceGeneratorClient
        self.accountAuthClient = accountAuthClient
        self.analyticsClient = analyticsClient
        self.accountInfoClient = accountInfoClient
        self.cohabitantClient = cohabitantClient
        self.cohabitantInvitationClient = cohabitantInvitationClient
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.signInWithAppleClient = signInWithAppleClient
        self.purchaseClient = purchaseClient
        self.houseworkTemplateClient = houseworkTemplateClient
        self.consentClient = consentClient
        self.mobileAdsClient = mobileAdsClient
        self.notificationPermissionClient = notificationPermissionClient
        self.notificationGuideStateClient = notificationGuideStateClient
        houseworkManager = .init(houseworkClient: houseworkClient)
        adsSetupUseCase = .init(consentClient: consentClient, mobileAdsClient: mobileAdsClient)
        notificationPermissionUseCase = .init(
            notificationPermissionClient: notificationPermissionClient,
            notificationGuideStateClient: notificationGuideStateClient
        )
    }

}

// MARK: Preview用の定義

public extension AppDependencies {

    static let previewValue: Self = .init()

}

public extension EnvironmentValues {

    @Entry var appDependencies: AppDependencies = .init()

}
