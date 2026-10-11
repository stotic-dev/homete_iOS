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

    /// サンプルの家事の担当者として出すメンバー
    ///
    /// 実際のメンバー名を出すと本物の記録と見分けにくいため、架空の名前にする。
    public static var members: CohabitantMemberList {
        .init(
            value: [
                .init(
                    id: ownId,
                    userName: LocalizedStringResource.localized("たろう", comment: "チュートリアルの見本で、自分として出す架空の名前").resolved()
                ),
                .init(
                    id: partnerId,
                    userName: LocalizedStringResource.localized("はなこ", comment: "チュートリアルの見本で、パートナーとして出す架空の名前")
                        .resolved()
                ),
            ],
            ownId: ownId
        )
    }

    /// 今日の家事のサンプル
    ///
    /// 未完了の家事と、パートナーと自分がそれぞれ完了した家事を含める。
    /// パートナーが完了した家事にはまだありがとうを伝えていない状態にし、ハートを押せる見た目にする。
    /// - Parameter locale: 家事の名前の言語。`nil`ならアプリが表示している言語
    public static func items(today: Date, locale: Locale? = nil) -> [HouseworkItem] {
        let title = { (resource: LocalizedStringResource) in resource.resolved(locale: locale) }
        return [
            item(
                id: "1",
                title: title(.localized("ゴミ出し", comment: "チュートリアルの見本で出す家事の名前")),
                point: 10,
                today: today,
                executorId: partnerId
            ),
            item(
                id: "2",
                title: title(.localized("食器洗い", comment: "チュートリアルの見本で出す家事の名前")),
                point: 20,
                today: today,
                executorId: ownId
            ),
            item(id: "3", title: title(.localized("洗濯", comment: "チュートリアルの見本で出す家事の名前")), point: 20, today: today),
            item(id: "4", title: title(.localized("お風呂掃除", comment: "チュートリアルの見本で出す家事の名前")), point: 30, today: today),
            item(id: "5", title: title(.localized("夕食の準備", comment: "チュートリアルの見本で出す家事の名前")), point: 40, today: today),
        ]
    }

    /// サンプルの家事を、指定日の家事一覧として返す
    /// - Parameter locale: 家事の名前の言語。`nil`ならアプリが表示している言語
    public static func dailyList(today: Date, locale: Locale? = nil) -> DailyHouseworkList {
        .init(
            items: items(today: today, locale: locale),
            metaData: .init(indexedDate: .init(value: today), expiredAt: .distantFuture)
        )
    }

}

private extension HouseworkTutorialSample {

    static let ownId = "tutorial_own"
    static let partnerId = "tutorial_partner"

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
