//
//  AppDependencies+liveValue.swift
//

import HometeDomain

// MARK: Live用の定義

public extension AppDependencies {

    static let liveValue: Self = .init(
        nonceGeneratorClient: .liveValue,
        accountAuthClient: .liveValue,
        analyticsClient: .liveValue,
        accountInfoClient: .liveValue,
        cohabitantClient: .liveValue,
        cohabitantInvitationClient: .liveValue,
        houseworkClient: .liveValue,
        cohabitantPushNotificationClient: .liveValue,
        signInWithAppleClient: .liveValue,
        purchaseClient: livePurchaseClient,
        houseworkTemplateClient: .liveValue,
        consentClient: liveConsentClient,
        mobileAdsClient: .liveValue,
        notificationPermissionClient: liveNotificationPermissionClient,
        notificationGuideStateClient: .liveValue
    )

}

#if os(iOS)
private let livePurchaseClient: PurchaseClient = .liveValue
private let liveConsentClient: ConsentClient = .liveValue
private let liveNotificationPermissionClient: NotificationPermissionClient = .liveValue
#else
private let livePurchaseClient: PurchaseClient = .previewValue
private let liveConsentClient: ConsentClient = .previewValue
private let liveNotificationPermissionClient: NotificationPermissionClient = .previewValue
#endif
