//
//  PushNotificationContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/12.
//

import Foundation

/// 同居人へ送るプッシュ通知の内容
///
/// 文面は送る側の端末の言語で組み立てるが、受け取った端末では`message`から受け取った側の言語で組み立て直す
/// （Notification Service Extension）。そのため文面そのものではなく、通知の種類と差し込む値を持つ。
public struct PushNotificationContent: Equatable, Sendable {

    public let message: Message
    /// ふりかえり通知の予約用データ。付けないときは`nil`
    public let completedData: HouseworkCompletedNotificationData?

    public init(message: Message, completedData: HouseworkCompletedNotificationData? = nil) {
        self.message = message
        self.completedData = completedData
    }

}

public extension PushNotificationContent {

    /// 通知の種類と、文面に差し込む値
    enum Message: Equatable, Sendable, Codable {

        /// 自分で終えた家事の完了
        case completed(executorName: String, houseworkTitle: String, comment: String)
        /// 他の人が担当した家事を、代わりに完了にした
        /// - Parameters:
        ///   - reporterName: 完了にした人の名前
        ///   - executorNames: 担当者の名前（完了にした人が含まれることもある）
        case proxyCompleted(reporterName: String, executorNames: [String], houseworkTitle: String, comment: String)
        /// まとめて完了にした
        case completedBulk(executorName: String, count: Int)
        /// ありがとうが届いた
        case thanks(senderName: String, houseworkTitle: String, comment: String)

    }

    /// 通知のタイトル
    /// - Parameter locale: 文面の言語。`nil`ならアプリが表示している言語
    func title(locale: Locale? = nil) -> String {
        switch message {
        case let .completed(executorName, _, _),
             let .completedBulk(executorName, _):
            LocalizedStringResource.localized("\(executorName)さんが家事を終えました").resolved(locale: locale)

        case let .proxyCompleted(reporterName, _, _, _):
            LocalizedStringResource.localized("\(reporterName)さんが家事の完了を記録しました").resolved(locale: locale)

        case let .thanks(senderName, houseworkTitle, _):
            LocalizedStringResource.localized(
                "\(senderName)さんから「\(houseworkTitle)」にありがとうが届きました",
                comment: "1つめは送った人の名前、2つめは家事の名前"
            )
            .resolved(locale: locale)
        }
    }

    /// 通知の本文
    /// - Parameter locale: 文面の言語。`nil`ならアプリが表示している言語
    func body(locale: Locale? = nil) -> String {
        switch message {
        case let .completed(_, houseworkTitle, comment):
            Self.withComment(
                LocalizedStringResource.localized("「\(houseworkTitle)」が完了しました").resolved(locale: locale),
                comment: comment
            )

        case let .proxyCompleted(_, executorNames, houseworkTitle, comment):
            Self.withComment(
                LocalizedStringResource.localized(
                    "「\(houseworkTitle)」（担当：\(Self.executorsLabel(executorNames, locale: locale))）",
                    comment: "1つめは家事の名前、2つめは担当者の名前を並べたもの"
                )
                .resolved(locale: locale),
                comment: comment
            )

        case let .completedBulk(_, count):
            LocalizedStringResource.localized("\(count)件の家事が完了しました").resolved(locale: locale)

        case let .thanks(_, _, comment):
            comment
        }
    }

    /// 通知のdataとして送る文字列の辞書
    var payload: [String: String] {
        var payload = completedData?.payload ?? [:]
        if let encoded = try? JSONEncoder().encode(message),
           let messageJSON = String(data: encoded, encoding: .utf8) {
            payload[Self.messageKey] = messageJSON
        }
        return payload
    }

    /// 受け取った通知の`userInfo`から、組み立て直すための内容を復元する
    /// - Returns: 種類を読み取れない場合（古いアプリから届いた通知など）は`nil`
    init?(userInfo: [AnyHashable: Any]) {
        guard let messageJSON = userInfo[Self.messageKey] as? String,
              let message = try? JSONDecoder().decode(Message.self, from: Data(messageJSON.utf8)) else { return nil }

        self.init(message: message, completedData: HouseworkCompletedNotificationData(userInfo: userInfo))
    }

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
            message: .completed(executorName: executorName, houseworkTitle: houseworkTitle, comment: comment),
            completedData: data
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
        .init(
            message: .proxyCompleted(
                reporterName: reporterName,
                executorNames: executorNames,
                houseworkTitle: houseworkTitle,
                comment: comment
            ),
            completedData: data
        )
    }

    static func completedBulkMessage(
        executorName: String,
        count: Int,
        data: HouseworkCompletedNotificationData
    ) -> Self {
        .init(message: .completedBulk(executorName: executorName, count: count), completedData: data)
    }

    static func thanksMessage(senderName: String, houseworkTitle: String, comment: String) -> Self {
        .init(message: .thanks(senderName: senderName, houseworkTitle: houseworkTitle, comment: comment))
    }

}

private extension PushNotificationContent {

    static let messageKey = "message"

    static func withComment(_ message: String, comment: String) -> String {
        comment.isEmpty ? message : "\(message)\n\(comment)"
    }

    /// 担当者の名前を「Aさん・Bさん」のように並べる
    static func executorsLabel(_ names: [String], locale: Locale?) -> String {
        names
            .map { LocalizedStringResource.localized("\($0)さん", comment: "担当者の名前に付ける敬称").resolved(locale: locale) }
            .joined(
                separator: LocalizedStringResource.localized("・", comment: "名前を並べるときの区切り（例: Aさん・Bさん、月曜日・木曜日）")
                    .resolved(locale: locale)
            )
    }

}
