//
//  PushNotificationContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/12.
//

public struct PushNotificationContent: Equatable, Sendable {

    public let title: String
    public let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

}

public extension PushNotificationContent {

    static func addNewHouseworkItem(_ houseworkTitle: String) -> Self {
        .init(
            title: "新しい家事が登録されました",
            message: houseworkTitle
        )
    }

    static func completedMessage(executorName: String, houseworkTitle: String) -> Self {
        .init(
            title: "\(executorName)さんが家事を終えました",
            message: "「\(houseworkTitle)」が完了しました"
        )
    }

    static func completedBulkMessage(executorName: String, count: Int) -> Self {
        .init(
            title: "\(executorName)さんが家事を終えました",
            message: "\(count)件の家事が完了しました"
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
