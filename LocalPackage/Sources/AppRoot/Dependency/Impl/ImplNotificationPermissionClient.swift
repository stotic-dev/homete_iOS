//
//  ImplNotificationPermissionClient.swift
//

#if os(iOS)
import HometeDomain
import UIKit
import UserNotifications

public extension NotificationPermissionClient {

    static let liveValue: NotificationPermissionClient = .init(
        requestAuthorization: { await requestAuthorization() },
        registerForRemoteNotifications: { await registerForRemoteNotificationsOnMain() },
        isAuthorizationDetermined: { await isAuthorizationDetermined() }
    )

}

private extension NotificationPermissionClient {

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("[Notifications] Authorization error: \(error)")
            return false
        }
    }

    @MainActor
    static func registerForRemoteNotificationsOnMain() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    static func isAuthorizationDetermined() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus != .notDetermined
    }

}
#endif
