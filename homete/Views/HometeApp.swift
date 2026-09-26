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

    func application(
        _: UIApplication,
        // swiftlint:disable:next discouraged_optional_collection
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase
        setupFirebase()

        // Initialize RevenueCat
        setupRevenueCat()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        return true
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard Messaging.messaging().apnsToken != deviceToken else { return }
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
    }

    /// 同居人が今日の家事を完了したことを知らせるサイレント通知を受け取り、ふりかえり通知を予約する
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        guard let data = HouseworkCompletedNotificationData(userInfo: userInfo) else { return .noData }
        // 起動中は家事一覧の購読（HouseworkListStore）が同じ完了を見て予約するので、ここでは予約しない
        guard application.applicationState != .active else { return .noData }

        await AppDependencies.liveValue.dailyCompletionReminderUseCase.handleCompleted(
            data,
            now: .now,
            calendar: .autoupdatingCurrent
        )
        return .newData
    }

}

// MARK: - setup

private extension AppDelegate {

    func setupFirebase() {
        // App Checkのプロバイダ登録はFirebaseApp.configure()より前に行う必要がある。
        AppCheckConfigurator.configure(usesDebugProvider: usesAppCheckDebugProvider)

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

    /// Xcodeから実行するローカルビルドかどうか。
    ///
    /// Stg構成はTestFlight配布でありながらDEBUGを定義している（開発用のFirebaseプロジェクトを
    /// 参照するため）ので、DEBUGだけではローカルビルドと区別できない。Stg構成にだけ定義した
    /// STGフラグで除外する。
    var usesAppCheckDebugProvider: Bool {
        #if DEBUG && !STG
        true
        #else
        false
        #endif
    }

    func setupRevenueCat() {
        guard !isXcodePreview, !isUnitTestMode else { return }
        RevenueCatClient.shared.initialize()
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
