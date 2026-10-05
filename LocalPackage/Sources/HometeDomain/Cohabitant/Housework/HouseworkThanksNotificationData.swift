//
//  HouseworkThanksNotificationData.swift
//  LocalPackage
//

import Foundation

/// ありがとうを同居人へ知らせる通知に載せる付加情報
///
/// 通知をタップして開いたときに、ありがとうが届いた家事の詳細画面を開くために使う。
/// FCMのdataは文字列の値しか持てないため、文字列の辞書との相互変換を持つ。
public struct HouseworkThanksNotificationData: Equatable, Sendable {

    /// ありがとうが届いた家事のID
    public let houseworkId: String

    public init(houseworkId: String) {
        self.houseworkId = houseworkId
    }

}

public extension HouseworkThanksNotificationData {

    /// 通知のdataとして送る文字列の辞書
    var payload: [String: String] {
        [
            Self.typeKey: Self.typeValue,
            Self.houseworkIdKey: houseworkId,
        ]
    }

    /// 受け取った通知の`userInfo`から復元する
    /// - Returns: ありがとうの通知でない場合、または家事のIDが読み取れない場合は`nil`
    init?(userInfo: [AnyHashable: Any]) {
        guard userInfo[Self.typeKey] as? String == Self.typeValue,
              let houseworkId = userInfo[Self.houseworkIdKey] as? String,
              !houseworkId.isEmpty else { return nil }

        self.init(houseworkId: houseworkId)
    }

}

private extension HouseworkThanksNotificationData {

    static let typeKey = "type"
    static let typeValue = "houseworkThanks"
    static let houseworkIdKey = "houseworkId"

}
