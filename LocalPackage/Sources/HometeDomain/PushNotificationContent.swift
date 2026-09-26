//
//  PushNotificationContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/12.
//

import Foundation

public struct PushNotificationContent: Equatable, Sendable {

    public let title: String
    public let message: String
    /// 受け取った端末で通知の種類を判定するための付加情報
    /// - Note: 空でない場合、受け取った端末でNotification Service Extensionが起動する
    public let data: [String: String]

    public init(title: String, message: String, data: [String: String] = [:]) {
        self.title = title
        self.message = message
        self.data = data
    }

}

public extension PushNotificationContent {

    static func addNewHouseworkItem(_ houseworkTitle: String) -> Self {
        .init(
            title: "新しい家事が登録されました",
            message: houseworkTitle
        )
    }

    static func completedMessage(executorName: String, houseworkTitle: String, houseworkDate: Date) -> Self {
        .init(
            title: "\(executorName)さんが家事を終えました",
            message: "「\(houseworkTitle)」が完了しました",
            data: HouseworkCompletedNotificationData(houseworkDate: houseworkDate).payload
        )
    }

    static func completedBulkMessage(executorName: String, count: Int, houseworkDate: Date) -> Self {
        .init(
            title: "\(executorName)さんが家事を終えました",
            message: "\(count)件の家事が完了しました",
            data: HouseworkCompletedNotificationData(houseworkDate: houseworkDate).payload
        )
    }

    static func thanksMessage(senderName: String, houseworkTitle: String, comment: String) -> Self {
        .init(
            title: "\(senderName)さんから「\(houseworkTitle)」にありがとうが届きました",
            message: comment
        )
    }

    static func thanksBulkMessage(senderName: String, count: Int) -> Self {
        .init(
            title: "\(senderName)さんからありがとうが届きました",
            message: "\(count)件の家事にありがとうが届きました"
        )
    }

}
