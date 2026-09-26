//
//  HouseworkCompletedNotificationData.swift
//  LocalPackage
//

import Foundation

/// 家事の完了を同居人へ知らせるサイレント通知に載せる付加情報
///
/// 完了した家事が「今日」の家事かどうかを、受け取った端末で判定するために使う。
/// FCMのdataは文字列の値しか持てないため、文字列の辞書との相互変換を持つ。
/// - Note: 古いアプリは同じdataを表示する完了通知に載せて送るため、Notification Service Extensionでも読む
public struct HouseworkCompletedNotificationData: Equatable, Sendable {

    /// 完了した家事の日付（`HouseworkIndexedDate.value`）
    public let houseworkDate: Date

    public init(houseworkDate: Date) {
        self.houseworkDate = houseworkDate
    }

}

public extension HouseworkCompletedNotificationData {

    /// 通知のdataとして送る文字列の辞書
    var payload: [String: String] {
        [
            Self.typeKey: Self.typeValue,
            Self.houseworkDateKey: String(Int(houseworkDate.timeIntervalSince1970)),
        ]
    }

    /// 受け取った通知の`userInfo`から復元する
    /// - Returns: 家事の完了通知でない場合、または日付が読み取れない場合は`nil`
    init?(userInfo: [AnyHashable: Any]) {
        guard userInfo[Self.typeKey] as? String == Self.typeValue,
              let rawDate = userInfo[Self.houseworkDateKey] as? String,
              let seconds = TimeInterval(rawDate) else { return nil }

        self.init(houseworkDate: Date(timeIntervalSince1970: seconds))
    }

}

private extension HouseworkCompletedNotificationData {

    static let typeKey = "type"
    static let typeValue = "houseworkCompleted"
    static let houseworkDateKey = "houseworkDate"

}
