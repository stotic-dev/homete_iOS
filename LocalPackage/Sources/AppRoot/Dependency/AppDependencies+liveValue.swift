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
        notificationGuideStateClient: .liveValue,
        pasteboardClient: livePasteboardClient,
        debugAuthClient: liveDebugAuthClient
    )

}

#if os(iOS)
private let livePurchaseClient: PurchaseClient = .liveValue
private let liveConsentClient: ConsentClient = .liveValue
private let liveNotificationPermissionClient: NotificationPermissionClient = .liveValue
private let livePasteboardClient: PasteboardClient = .liveValue
#else
private let livePurchaseClient: PurchaseClient = .previewValue
private let liveConsentClient: ConsentClient = .previewValue
private let liveNotificationPermissionClient: NotificationPermissionClient = .previewValue
private let livePasteboardClient: PasteboardClient = .previewValue
#endif

// デバッグメニューからしか使わないため、リリースビルドには実装を持ち込まない
#if DEBUG
private let liveDebugAuthClient: DebugAuthClient = .liveValue
#else
private let liveDebugAuthClient: DebugAuthClient = .previewValue
#endif
