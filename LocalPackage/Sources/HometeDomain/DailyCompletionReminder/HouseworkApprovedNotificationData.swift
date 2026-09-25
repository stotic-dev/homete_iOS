//
//  HouseworkApprovedNotificationData.swift
//  LocalPackage
//

import Foundation

/// 家事の承認通知に載せる付加情報
///
/// 承認された家事が「今日」の家事かどうかを、受け取った端末のNotification Service Extensionで
/// 判定するために使う。FCMのdataは文字列の値しか持てないため、文字列の辞書との相互変換を持つ。
public struct HouseworkApprovedNotificationData: Equatable, Sendable {

    /// 承認された家事の日付（`HouseworkIndexedDate.value`）
    public let houseworkDate: Date

    public init(houseworkDate: Date) {
        self.houseworkDate = houseworkDate
    }

}

public extension HouseworkApprovedNotificationData {

    /// 通知のdataとして送る文字列の辞書
    var payload: [String: String] {
        [
            Self.typeKey: Self.typeValue,
            Self.houseworkDateKey: String(Int(houseworkDate.timeIntervalSince1970)),
        ]
    }

    /// 受け取った通知の`userInfo`から復元する
    /// - Returns: 家事の承認通知でない場合、または日付が読み取れない場合は`nil`
    init?(userInfo: [AnyHashable: Any]) {
        guard userInfo[Self.typeKey] as? String == Self.typeValue,
              let rawDate = userInfo[Self.houseworkDateKey] as? String,
              let seconds = TimeInterval(rawDate) else { return nil }

        self.init(houseworkDate: Date(timeIntervalSince1970: seconds))
    }

}

private extension HouseworkApprovedNotificationData {

    static let typeKey = "type"
    static let typeValue = "houseworkApproved"
    static let houseworkDateKey = "houseworkDate"

}
