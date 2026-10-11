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
/// 一度伝えたものは、どこまで見たかを届いた日時で覚えておき、次からは数えない。
public struct ReceivedThanksSummary: Equatable, Sendable {

    /// 届いたありがとうの件数。1つの家事に2人から届いたら2件と数える
    public let count: Int
    /// 送ってくれた、自分以外のメンバーの名前（メンバー一覧の順）。グループを抜けた人は含めない
    public let senderNames: [String]
    /// 数えたありがとうのうち、最後に届いた日時。見たことを記録するのに使う。届いていなければ`nil`
    public let latestSentAt: Date?

    public init(count: Int, senderNames: [String], latestSentAt: Date?) {
        self.count = count
        self.senderNames = senderNames
        self.latestSentAt = latestSentAt
    }

    /// 届いたことを伝えるかどうか
    public var hasReceived: Bool {
        count > 0
    }

}

public extension ReceivedThanksSummary {

    /// - Parameters:
    ///   - ownUserId: 見ている本人。メンバー一覧の読み込みを待たずに判定できるよう、ログイン情報から渡す
    ///   - seenUntil: 前に見た、最後に届いたありがとうの日時。これ以前に届いたものは数えない。まだ見ていなければ`nil`
    static func make( // swiftlint:disable:this function_parameter_count
        storedAllItems: StoredAllHouseworkList,
        members: CohabitantMemberList,
        ownUserId: String,
        seenUntil: Date?,
        now: Date,
        calendar: Calendar
    ) -> Self {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        // 前の日の家事に後から届くこともあるため、家事の日付ではなく届いた日時で絞る
        let receivedThanks = storedAllItems.value
            .flatMap(\.items)
            .filter { $0.state == .completed && $0.executors.contains { $0.userId == ownUserId } }
            .flatMap { item in
                item.thanks.filter { senderId, thanks in
                    senderId != ownUserId && thanks.sentAt >= yesterday && seenUntil.map { thanks.sentAt > $0 } ?? true
                }
            }
        let senderIds = Set(receivedThanks.map(\.key))

        return .init(
            count: receivedThanks.count,
            senderNames: members.others
                .filter { senderIds.contains($0.id) }
                .map(\.userName),
            latestSentAt: receivedThanks.map(\.value.sentAt).max()
        )
    }

}
