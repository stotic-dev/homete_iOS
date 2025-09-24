//
//  HometeApp.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/04/22.
//

import FirebaseCore
import FirebaseMessaging
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    let isXcodePreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
        
    func application(
        _ application: UIApplication,
        // swiftlint:disable:next discouraged_optional_collection
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        #if DEBUG
        if isXcodePreview {
            
            guard let devPlistFilePath = (
                Bundle.main.url(
                    forResource: "GoogleService-Info-dev",
                    withExtension: "plist"
                )?
                    .path()
            ),
                  let firebaseOption = FirebaseOptions(contentsOfFile: devPlistFilePath) else { return true }
            FirebaseApp.configure(options: firebaseOption)
        }
        #else
        FirebaseApp.configure()
        #endif
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        guard Messaging.messaging().apnsToken != deviceToken else { return }
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
    }
}

extension AppDelegate: MessagingDelegate {
    
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        print("didReceiveRegistrationToken: \(fcmToken ?? "nil")")
        DispatchQueue.main.async {
            
            NotificationCenter.default.post(name: .didReceiveFcmToken, object: fcmToken)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.sound]
    }
}

@main
struct HometeApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.appDependencies) var appDependencies
    
    @State var fcmToken: String?
    
    var body: some Scene {
        WindowGroup {
            RootView(
                accountAuthStore: .init(appDependencies: appDependencies),
                accountStore: .init(appDependencies: appDependencies)
            )
        }
    }
}
