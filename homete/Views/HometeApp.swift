//
//  HometeApp.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/04/22.
//

import AppRoot
import FirebaseCore
import FirebaseMessaging
import HometeDomain
import HometeInfrastructure
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {

    let isXcodePreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
    let isUnitTestMode = ProcessInfo.processInfo.arguments.contains("isUnitTestMode")
    let adsSetupUseCase = AdsSetupUseCase(
        consentClient: .liveValue,
        appTrackingClient: .liveValue,
        mobileAdsClient: .liveValue
    )

    func application(
        _: UIApplication,
        // swiftlint:disable:next discouraged_optional_collection
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase
        setupFirebase()

        // Initialize Google Mobile Ads
        setupGoogleMobileAds()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        return true
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard Messaging.messaging().apnsToken != deviceToken else { return }
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
    }

}

// MARK: - setup

private extension AppDelegate {

    func setupFirebase() {
        #if DEBUG
        if !isXcodePreview, !isUnitTestMode {
            guard let devPlistFilePath = (
                Bundle.main.url(
                    forResource: "GoogleService-Info-dev",
                    withExtension: "plist"
                )?
                    .path()
            ),
                let firebaseOption = FirebaseOptions(contentsOfFile: devPlistFilePath) else { return }
            FirebaseApp.configure(options: firebaseOption)
        }
        #else
        FirebaseApp.configure()
        #endif
    }

    func setupGoogleMobileAds() {
        Task {
            await adsSetupUseCase.setup()
        }
    }

}

// MARK: - Delegate Conformances

extension AppDelegate: MessagingDelegate {

    nonisolated func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("didReceiveRegistrationToken: \(fcmToken ?? "nil")")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didReceiveFcmToken, object: fcmToken)
        }
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.sound]
    }

}

@main
struct HometeApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State var fcmToken: String?

    var body: some Scene {
        WindowGroup {
            if delegate.isUnitTestMode {
                EmptyView()
            } else {
                RootView.make(dependencies: .liveValue)
            }
        }
    }

}
