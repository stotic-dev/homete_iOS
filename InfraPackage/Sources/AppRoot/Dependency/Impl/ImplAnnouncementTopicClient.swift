//
//  ImplAnnouncementTopicClient.swift
//

import Foundation
import HometeDomain
import HometeInfrastructure

extension AnnouncementTopicClient {

    static let liveValue: AnnouncementTopicClient = .init {
        // 未設定の端末は受け取る設定として扱う
        UserDefaults.standard.object(forKey: Self.isEnabledKey) as? Bool ?? true
    } saveIsEnabled: {
        UserDefaults.standard.set($0, forKey: Self.isEnabledKey)
    } subscribe: {
        await MessagingTopicService.subscribe(Self.topic)
    } unsubscribe: {
        await MessagingTopicService.unsubscribe(Self.topic)
    }

}

private extension AnnouncementTopicClient {

    static let isEnabledKey = "isAnnouncementNotificationEnabled"
    /// homete_backendがお知らせの通知を送るトピック
    static let topic = "announcements"

}
