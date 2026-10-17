//
//  ContributionMonthlySummary.swift
//  LocalPackage
//

import Foundation
import HometeDomain

/// ある月のメンバーごとのがんばり（ポイントと件数）
///
/// アプリを開かずにSiriの結果へ出すときに使う。値はダッシュボードの「今月のがんばり」と同じ集計にする。
public struct ContributionMonthlySummary: Equatable, Sendable {

    /// 集計した月（その月の中の日時）
    public let month: Date
    let pointSummary: AllUserPointSummary

    /// その月に完了した家事があるかどうか
    public var hasData: Bool {
        pointSummary.hasData
    }

    /// 完了した家事から集計する
    /// - Parameters:
    ///   - items: 集計する家事。その月以外の家事が含まれていてもよい
    ///   - members: 一覧に出すメンバー。家事をしていないメンバーも0ptで出す
    public static func make(
        items: [HouseworkItem],
        members: CohabitantMemberList,
        month: Date,
        myUserId: String,
        calendar: Calendar
    ) -> Self {
        .init(
            month: month,
            pointSummary: HouseworkContribution.make(by: items, calendar: calendar).calculatePointSummaries(
                month: month,
                calendar: calendar,
                members: members,
                myUserId: myUserId
            )
        )
    }

}
