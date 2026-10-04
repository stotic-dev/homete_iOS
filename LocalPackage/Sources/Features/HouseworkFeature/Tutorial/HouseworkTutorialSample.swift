//
//  HouseworkTutorialSample.swift
//  LocalPackage
//

import Foundation
import HometeDomain

/// チュートリアルで、家事ボードやダッシュボードのUIに渡すサンプルの家事
///
/// グループを作った直後は家事が1件もなく、完了した家事のハートや割合グラフを見せられないため、
/// 本番と同じUIにこのサンプルを渡して表示する。保存はしない。
public enum HouseworkTutorialSample {

    /// パートナーの名前がまだ読み込めていないときに使うユーザーID
    static let placeholderPartnerId = "tutorial_partner"

    /// 今日の家事のサンプル
    ///
    /// 未完了の家事と、パートナーと自分がそれぞれ完了した家事を含める。
    /// パートナーが完了した家事にはまだありがとうを伝えていない状態にし、ハートを押せる見た目にする。
    public static func items(today: Date, members: CohabitantMemberList) -> [HouseworkItem] {
        let ownId = members.ownId
        let partnerId = members.others.first?.id ?? placeholderPartnerId
        return [
            item(id: "1", title: "ゴミ出し", point: 10, today: today, executorId: partnerId),
            item(id: "2", title: "食器洗い", point: 20, today: today, executorId: ownId),
            item(id: "3", title: "洗濯", point: 20, today: today),
            item(id: "4", title: "お風呂掃除", point: 30, today: today),
            item(id: "5", title: "夕食の準備", point: 40, today: today),
        ]
    }

    /// サンプルに出すメンバー
    ///
    /// パートナーの名前がまだ読み込めていなければ、仮の名前で出す。
    public static func members(ownId: String, ownUserName: String, others: [CohabitantMember]) -> CohabitantMemberList {
        let partner = others.first ?? .init(id: placeholderPartnerId, userName: "パートナー")
        return .init(
            value: [.init(id: ownId, userName: ownUserName), partner],
            ownId: ownId
        )
    }

    /// サンプルの家事を、指定日の家事一覧として返す
    public static func dailyList(today: Date, members: CohabitantMemberList) -> DailyHouseworkList {
        .init(
            items: items(today: today, members: members),
            metaData: .init(indexedDate: .init(value: today), expiredAt: .distantFuture)
        )
    }

}

private extension HouseworkTutorialSample {

    /// - Parameter executorId: 完了した人。`nil`なら未完了の家事にする
    static func item(id: String, title: String, point: Int, today: Date, executorId: String? = nil) -> HouseworkItem {
        .init(
            id: "tutorial_\(id)",
            indexedDate: .init(value: today),
            title: title,
            point: point,
            state: executorId == nil ? .incomplete : .completed,
            executors: executorId.map { [.solo(userId: $0, point: point)] } ?? [],
            effort: .normal,
            executedAt: executorId == nil ? nil : today,
            expiredAt: .distantFuture,
            templateHouseworkItemId: nil
        )
    }

}
