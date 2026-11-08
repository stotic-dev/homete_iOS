//
//  AnnouncementNotificationData.swift
//  LocalPackage
//

/// 運営からのお知らせの通知に載る付加情報
///
/// 通知はサーバー（homete_backend）がFCMのトピックへ送るため、アプリは受け取るだけで組み立てない。
/// 通知の後に取り下げられたり、端末のバージョンが対象外だったりして一覧に無いことがあるため、
/// お知らせのIDは持たず、お知らせの通知かどうかだけを判別する。
public struct AnnouncementNotificationData: Equatable, Sendable {

    public init() {}

}

public extension AnnouncementNotificationData {

    /// 受け取った通知の`userInfo`から復元する
    /// - Returns: お知らせの通知でない場合は`nil`
    init?(userInfo: [AnyHashable: Any]) {
        guard userInfo[Self.typeKey] as? String == Self.typeValue else { return nil }

        self.init()
    }

}

private extension AnnouncementNotificationData {

    static let typeKey = "type"
    static let typeValue = "announcement"

}
