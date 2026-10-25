//
//  InquiryReplyNotificationData.swift
//  LocalPackage
//

import Foundation

/// 問い合わせに運営の返信が届いたことを知らせる通知に載る付加情報
///
/// 通知をタップして開いたときに、返信が届いた問い合わせの詳細画面を開くために使う。
/// 通知はサーバー（homete_backend）が送るため、アプリは受け取るだけで組み立てない。
public struct InquiryReplyNotificationData: Equatable, Sendable {

    /// 返信が届いた問い合わせのID
    public let inquiryId: String

    public init(inquiryId: String) {
        self.inquiryId = inquiryId
    }

}

public extension InquiryReplyNotificationData {

    /// 受け取った通知の`userInfo`から復元する
    /// - Returns: 返信の通知でない場合、または問い合わせのIDが読み取れない場合は`nil`
    init?(userInfo: [AnyHashable: Any]) {
        guard userInfo[Self.typeKey] as? String == Self.typeValue,
              let inquiryId = userInfo[Self.inquiryIdKey] as? String,
              !inquiryId.isEmpty else { return nil }

        self.init(inquiryId: inquiryId)
    }

}

private extension InquiryReplyNotificationData {

    static let typeKey = "type"
    static let typeValue = "inquiryReply"
    static let inquiryIdKey = "inquiryId"

}
