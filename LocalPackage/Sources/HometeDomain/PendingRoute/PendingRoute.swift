//
//  PendingRoute.swift
//  LocalPackage
//

import Foundation

/// 通知をタップして開いたときに表示する画面
public enum PendingRoute: Equatable, Sendable {

    /// 家事の詳細画面
    case houseworkDetail(houseworkId: String)

}

public extension PendingRoute {

    /// タップされた通知の`userInfo`から開く画面を決める
    /// - Returns: 開く画面が決まっていない通知の場合は`nil`
    init?(userInfo: [AnyHashable: Any]) {
        guard let data = HouseworkThanksNotificationData(userInfo: userInfo) else { return nil }

        self = .houseworkDetail(houseworkId: data.houseworkId)
    }

}
