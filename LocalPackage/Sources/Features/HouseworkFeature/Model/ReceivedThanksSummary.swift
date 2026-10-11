//
//  ReceivedThanksSummary.swift
//  LocalPackage
//

import Foundation
import HometeDomain

/// 自分が終えた家事に、同居人から届いたありがとう
///
/// ダッシュボードのコメントカードで、届いたことをほめっとが伝えるのに使う。
/// 夜遅くに届いたありがとうにも翌朝気づけるよう、感謝の促しと同じく今日と昨日に届いたものを対象にする。
public struct ReceivedThanksSummary: Equatable, Sendable {

    /// 届いたありがとうの件数。1つの家事に2人から届いたら2件と数える
    public let count: Int
    /// 送ってくれた、自分以外のメンバーの名前（メンバー一覧の順）。グループを抜けた人は含めない
    public let senderNames: [String]

    public init(count: Int, senderNames: [String]) {
        self.count = count
        self.senderNames = senderNames
    }

    /// 届いたことを伝えるかどうか
    public var hasReceived: Bool {
        count > 0
    }

}

public extension ReceivedThanksSummary {

    /// - Parameter ownUserId: 見ている本人。メンバー一覧の読み込みを待たずに判定できるよう、ログイン情報から渡す
    static func make(
        storedAllItems: StoredAllHouseworkList,
        members: CohabitantMemberList,
        ownUserId: String,
        now: Date,
        calendar: Calendar
    ) -> Self {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        // 前の日の家事に後から届くこともあるため、家事の日付ではなく届いた日時で絞る
        let senderIds = storedAllItems.value
            .flatMap(\.items)
            .filter { $0.state == .completed && $0.executors.contains { $0.userId == ownUserId } }
            .flatMap { item in
                item.thanks
                    .filter { senderId, thanks in senderId != ownUserId && thanks.sentAt >= yesterday }
                    .map(\.key)
            }
        let senderIdSet = Set(senderIds)

        return .init(
            count: senderIds.count,
            senderNames: members.others
                .filter { senderIdSet.contains($0.id) }
                .map(\.userName)
        )
    }

}
