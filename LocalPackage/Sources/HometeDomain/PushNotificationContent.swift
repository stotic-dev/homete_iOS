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

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

}

public extension PushNotificationContent {

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
