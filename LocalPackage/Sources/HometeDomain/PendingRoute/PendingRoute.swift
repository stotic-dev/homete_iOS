//
//  PendingRoute.swift
//  LocalPackage
//

import Foundation

/// 通知のタップやApp Intentでアプリを開いたときに表示する画面
public enum PendingRoute: Equatable, Sendable {

    /// 家事の詳細画面（通知のタップ）
    case houseworkDetail(houseworkId: String)
    /// 今日の家事の完了シート（App Intent）
    /// - Note: 家事は日ごとに別のIDになるため、日をまたいでも変わらない家事の名前で指定する
    case houseworkComplete(houseworkTitle: String)
    /// がんばりの分析画面（App Intent）
    case contributionAnalytics

}

public extension PendingRoute {

    /// タップされた通知の`userInfo`から開く画面を決める
    /// - Returns: 開く画面が決まっていない通知の場合は`nil`
    init?(userInfo: [AnyHashable: Any]) {
        guard let data = HouseworkThanksNotificationData(userInfo: userInfo) else { return nil }

        self = .houseworkDetail(houseworkId: data.houseworkId)
    }

}
