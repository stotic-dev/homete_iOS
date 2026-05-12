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

    static func requestReviewMessage(houseworkTitle: String) -> Self {
        .init(
            title: "確認が必要な家事があります",
            message: "問題なければ「\(houseworkTitle)」の完了に感謝を伝えましょう！"
        )
    }

    static func approvedMessage(reviwerName: String, houseworkTitle: String, comment: String) -> Self {
        .init(
            title: "\(reviwerName)が「\(houseworkTitle)」を承認しました！",
            message: comment
        )
    }

    static func rejectedMessage(reviwerName _: String, houseworkTitle: String, comment: String) -> Self {
        .init(
            title: "「\(houseworkTitle)」を再確認してください",
            message: comment
        )
    }

}
