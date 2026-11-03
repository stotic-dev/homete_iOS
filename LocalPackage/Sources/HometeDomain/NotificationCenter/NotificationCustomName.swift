//
//  NotificationCustomName.swift
//

import Foundation

public extension Notification.Name {

    static let didReceiveFcmToken = Notification.Name("didReceiveFcmToken")
    /// アプリを開いている間に、運営からのお知らせの通知を受け取った
    static let didReceiveAnnouncementNotification = Notification.Name("didReceiveAnnouncementNotification")

}
