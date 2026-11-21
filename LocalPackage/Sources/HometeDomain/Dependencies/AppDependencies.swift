//
//  AppDependencies.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import Foundation

public struct AppDependencies: Sendable {

    public let nonceGeneratorClient: NonceGenerationClient
    public let accountAuthClient: AccountAuthClient
    public let analyticsClient: AnalyticsClient
    public let errorReportClient: ErrorReportClient
    public let accountInfoClient: AccountInfoClient
    public let cohabitantClient: CohabitantClient
    public let cohabitantInvitationClient: CohabitantInvitationClient
    public let sentInvitationClient: SentInvitationClient
    public let houseworkClient: HouseworkClient
    public let houseworkImageClient: HouseworkImageClient
    public let cohabitantPushNotificationClient: CohabitantPushNotificationClient
    public let signInWithAppleClient: SignInWithAppleClient
    public let purchaseClient: PurchaseClient
    public let houseworkTemplateClient: HouseworkTemplateClient
    public let frequentHouseworkClient: FrequentHouseworkClient
    public let houseworkEntryHistoryClient: HouseworkEntryHistoryClient
    public let consentClient: ConsentClient
    public let mobileAdsClient: MobileAdsClient
    public let notificationPermissionClient: NotificationPermissionClient
    public let notificationGuideStateClient: NotificationGuideStateClient
    public let appReviewStateClient: AppReviewStateClient
    public let registrationTutorialStateClient: RegistrationTutorialStateClient
    public let screenTutorialStateClient: ScreenTutorialStateClient
    public let pasteboardClient: PasteboardClient
    public let dailyCompletionReminderClient: DailyCompletionReminderClient
    public let remoteConfigClient: RemoteConfigClient
    public let maintenanceStateClient: MaintenanceStateClient
    public let encouragementCommentClient: EncouragementCommentClient
    public let encouragementCommentCacheClient: EncouragementCommentCacheClient
    public let intentDonationClient: IntentDonationClient
    public let inquiryClient: InquiryClient
    public let announcementClient: AnnouncementClient
    public let announcementTopicClient: AnnouncementTopicClient
    /// デバッグメニュー専用。リリースビルドでは何もしない実装が入る
    public let debugAuthClient: DebugAuthClient
    /// デバッグメニュー専用。リリースビルドでは何もしない実装が入る
    public let debugLocalDataClient: DebugLocalDataClient
    public let houseworkManager: HouseworkManager
    /// 広告の同意取得（ATT含む）とMobileAdsの初期化を行うUseCase
    public let adsSetupUseCase: AdsSetupUseCase
    /// プッシュ通知の権限リクエストを行うUseCase
    public let notificationPermissionUseCase: NotificationPermissionUseCase
    /// 今日完了した家事がある日に、ふりかえり通知を予約するUseCase
    public let dailyCompletionReminderUseCase: DailyCompletionReminderUseCase
    /// お知らせのPush通知の設定とトピックの購読をそろえるUseCase
    public let announcementTopicUseCase: AnnouncementTopicUseCase

    public init(
        nonceGeneratorClient: NonceGenerationClient = .previewValue,
        accountAuthClient: AccountAuthClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        errorReportClient: ErrorReportClient = .previewValue,
        accountInfoClient: AccountInfoClient = .previewValue,
        cohabitantClient: CohabitantClient = .previewValue,
        cohabitantInvitationClient: CohabitantInvitationClient = .previewValue,
        sentInvitationClient: SentInvitationClient = .previewValue,
        houseworkClient: HouseworkClient = .previewValue,
        houseworkImageClient: HouseworkImageClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        signInWithAppleClient: SignInWithAppleClient = .previewValue,
        purchaseClient: PurchaseClient = .previewValue,
        houseworkTemplateClient: HouseworkTemplateClient = .previewValue,
        frequentHouseworkClient: FrequentHouseworkClient = .previewValue,
        houseworkEntryHistoryClient: HouseworkEntryHistoryClient = .previewValue,
        consentClient: ConsentClient = .previewValue,
        mobileAdsClient: MobileAdsClient = .previewValue,
        notificationPermissionClient: NotificationPermissionClient = .previewValue,
        notificationGuideStateClient: NotificationGuideStateClient = .previewValue,
        appReviewStateClient: AppReviewStateClient = .previewValue,
        registrationTutorialStateClient: RegistrationTutorialStateClient = .previewValue,
        screenTutorialStateClient: ScreenTutorialStateClient = .previewValue,
        pasteboardClient: PasteboardClient = .previewValue,
        dailyCompletionReminderClient: DailyCompletionReminderClient = .previewValue,
        remoteConfigClient: RemoteConfigClient = .previewValue,
        maintenanceStateClient: MaintenanceStateClient = .previewValue,
        encouragementCommentClient: EncouragementCommentClient = .previewValue,
        encouragementCommentCacheClient: EncouragementCommentCacheClient = .previewValue,
        intentDonationClient: IntentDonationClient = .previewValue,
        inquiryClient: InquiryClient = .previewValue,
        announcementClient: AnnouncementClient = .previewValue,
        announcementTopicClient: AnnouncementTopicClient = .previewValue,
        debugAuthClient: DebugAuthClient = .previewValue,
        debugLocalDataClient: DebugLocalDataClient = .previewValue
    ) {
        self.nonceGeneratorClient = nonceGeneratorClient
        self.accountAuthClient = accountAuthClient
        self.analyticsClient = analyticsClient
        self.errorReportClient = errorReportClient
        self.accountInfoClient = accountInfoClient
        self.cohabitantClient = cohabitantClient
        self.cohabitantInvitationClient = cohabitantInvitationClient
        self.sentInvitationClient = sentInvitationClient
        self.houseworkClient = houseworkClient
        self.houseworkImageClient = houseworkImageClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.signInWithAppleClient = signInWithAppleClient
        self.purchaseClient = purchaseClient
        self.houseworkTemplateClient = houseworkTemplateClient
        self.frequentHouseworkClient = frequentHouseworkClient
        self.houseworkEntryHistoryClient = houseworkEntryHistoryClient
        self.consentClient = consentClient
        self.mobileAdsClient = mobileAdsClient
        self.notificationPermissionClient = notificationPermissionClient
        self.notificationGuideStateClient = notificationGuideStateClient
        self.appReviewStateClient = appReviewStateClient
        self.registrationTutorialStateClient = registrationTutorialStateClient
        self.screenTutorialStateClient = screenTutorialStateClient
        self.pasteboardClient = pasteboardClient
        self.dailyCompletionReminderClient = dailyCompletionReminderClient
        self.remoteConfigClient = remoteConfigClient
        self.maintenanceStateClient = maintenanceStateClient
        self.encouragementCommentClient = encouragementCommentClient
        self.encouragementCommentCacheClient = encouragementCommentCacheClient
        self.intentDonationClient = intentDonationClient
        self.inquiryClient = inquiryClient
        self.announcementClient = announcementClient
        self.announcementTopicClient = announcementTopicClient
        self.debugAuthClient = debugAuthClient
        self.debugLocalDataClient = debugLocalDataClient
        houseworkManager = .init(houseworkClient: houseworkClient)
        adsSetupUseCase = .init(consentClient: consentClient, mobileAdsClient: mobileAdsClient)
        notificationPermissionUseCase = .init(
            notificationPermissionClient: notificationPermissionClient,
            notificationGuideStateClient: notificationGuideStateClient
        )
        dailyCompletionReminderUseCase = .init(client: dailyCompletionReminderClient)
        announcementTopicUseCase = .init(client: announcementTopicClient)
    }

}

// MARK: Preview用の定義

public extension AppDependencies {

    static let previewValue: Self = .init()

}
