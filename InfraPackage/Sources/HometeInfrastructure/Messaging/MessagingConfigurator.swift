//
//  MessagingConfigurator.swift
//

import FirebaseMessaging
import Foundation
import HometeDomain

/// Firebase Cloud MessagingにAPNsのトークンを渡し、発行されたFCMトークンをアプリへ通知する。
public enum MessagingConfigurator {

    /// `Messaging`はデリゲートを弱参照で持つため、ここで保持する
    private static let delegate = FCMTokenDelegate()

    /// FCMトークンの受け取りを始める。受け取ったトークンは`.didReceiveFcmToken`で通知する
    public static func configure() {
        Messaging.messaging().delegate = delegate
    }

    /// APNsから受け取ったデバイストークンをFCMへ渡す
    public static func setAPNSToken(_ deviceToken: Data) {
        guard Messaging.messaging().apnsToken != deviceToken else { return }
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
    }

}

// MARK: - FCMTokenDelegate

private final class FCMTokenDelegate: NSObject, MessagingDelegate, Sendable {

    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("didReceiveRegistrationToken: \(fcmToken ?? "nil")")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didReceiveFcmToken, object: fcmToken)
        }
    }

}
