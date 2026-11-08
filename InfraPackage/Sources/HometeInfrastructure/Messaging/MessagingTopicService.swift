//
//  MessagingTopicService.swift
//

import FirebaseMessaging

/// Firebase Cloud Messagingのトピックの購読を扱う
/// - Note: FCMトークンが発行される前に呼んでも、SDKが発行を待ってから購読する
public enum MessagingTopicService {

    /// トピックを購読する。失敗してもSDKが再試行するため、ログに残すだけにする
    public static func subscribe(_ topic: String) async {
        do {
            try await Messaging.messaging().subscribe(toTopic: topic)
        } catch {
            print("Failed to subscribe to topic(\(topic)): \(error)")
        }
    }

    /// トピックの購読をやめる。失敗してもSDKが再試行するため、ログに残すだけにする
    public static func unsubscribe(_ topic: String) async {
        do {
            try await Messaging.messaging().unsubscribe(fromTopic: topic)
        } catch {
            print("Failed to unsubscribe from topic(\(topic)): \(error)")
        }
    }

}
