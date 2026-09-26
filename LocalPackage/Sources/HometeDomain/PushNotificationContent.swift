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

    /// 自分で終えた家事の完了通知
    /// - Parameters:
    ///   - comment: 完了時に添えたコメント。空なら本文に付けない
    ///   - data: ふりかえり通知の予約用データ。付けないときは`nil`
    static func completedMessage(
        executorName: String,
        houseworkTitle: String,
        comment: String,
        data: HouseworkCompletedNotificationData?
    ) -> Self {
        .init(
            title: "\(executorName)さんが家事を終えました",
            message: messageWithComment("「\(houseworkTitle)」が完了しました", comment: comment),
            data: data?.payload ?? [:]
        )
    }

    /// 他の人が担当した家事を、代わりに完了にしたときの通知
    /// - Parameters:
    ///   - reporterName: 完了にした人の名前
    ///   - executorNames: 担当者の名前（完了にした人が含まれることもある）
    ///   - comment: 完了時に添えたコメント。空なら本文に付けない
    ///   - data: ふりかえり通知の予約用データ。付けないときは`nil`
    static func proxyCompletedMessage(
        reporterName: String,
        executorNames: [String],
        houseworkTitle: String,
        comment: String,
        data: HouseworkCompletedNotificationData?
    ) -> Self {
        let executors = executorNames.map { "\($0)さん" }.joined(separator: "・")
        return .init(
            title: "\(reporterName)さんが家事の完了を記録しました",
            message: messageWithComment("「\(houseworkTitle)」（担当：\(executors)）", comment: comment),
            data: data?.payload ?? [:]
        )
    }

    static func completedBulkMessage(
        executorName: String,
        count: Int,
        data: HouseworkCompletedNotificationData
    ) -> Self {
        .init(
            title: "\(executorName)さんが家事を終えました",
            message: "\(count)件の家事が完了しました",
            data: data.payload
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

private extension PushNotificationContent {

    static func messageWithComment(_ message: String, comment: String) -> String {
        comment.isEmpty ? message : "\(message)\n\(comment)"
    }

}
