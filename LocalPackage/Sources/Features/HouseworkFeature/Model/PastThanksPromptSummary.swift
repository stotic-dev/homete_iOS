//
//  PastThanksPromptSummary.swift
//  LocalPackage
//

import Foundation
import HometeDomain

/// 昨日から7日前までに同居人がやってくれた家事のうち、まだありがとうを伝えていないもの
///
/// ダッシュボードの過去の促しと、過去のありがとう漏れの一覧で使う。家事の日付で判定する。
/// それより古い家事は、今からありがとうを送るのが不自然なので対象にしない。
public struct PastThanksPromptSummary: Equatable, Sendable {

    /// 何日前まで遡るか
    public static let pastDays = 7

    /// 日ごとの家事（日付の新しい順）。家事が無い日は含めない
    public let dailyItems: [DailyItems]
    /// まだありがとうを送っていない件数
    public let notSentCount: Int
    /// まだありがとうを送っていない家事を担当した、自分以外のメンバーの名前（メンバー一覧の順）
    public let executorNames: [String]

    public init(dailyItems: [DailyItems], notSentCount: Int, executorNames: [String]) {
        self.dailyItems = dailyItems
        self.notSentCount = notSentCount
        self.executorNames = executorNames
    }

    /// 過去の促しを出すかどうか
    public var shouldPrompt: Bool {
        notSentCount > 0
    }

}

public extension PastThanksPromptSummary {

    /// 1日分の、ありがとうを伝えられる家事
    struct DailyItems: Equatable, Sendable, Identifiable {

        /// 家事の日付（その日の0時）
        public let date: Date
        /// まだ送っていない → 送った、の順。それぞれ完了日時の新しい順
        public let items: [HouseworkBoardItem]

        public var id: Date {
            date
        }

        public init(date: Date, items: [HouseworkBoardItem]) {
            self.date = date
            self.items = items
        }

    }

    /// - Parameters:
    ///   - ownUserId: 見ている本人。メンバー一覧の読み込みを待たずに判定できるよう、ログイン情報から渡す
    ///   - keepingSentSince: この日時以降にありがとうを送った家事も残す。一覧で送った直後に行が消えて戸惑わないようにするため、一覧を開いた日時を渡す
    static func make(
        storedAllItems: StoredAllHouseworkList,
        members: CohabitantMemberList,
        ownUserId: String,
        now: Date,
        calendar: Calendar,
        keepingSentSince: Date? = nil
    ) -> Self {
        let today = calendar.startOfDay(for: now)
        let days = (1 ... pastDays).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }

        var notSentItems: [HouseworkBoardItem] = []
        let dailyItems = days.compactMap { day -> DailyItems? in
            let items = ThanksPromptSummary.thankableItems(
                on: [day],
                storedAllItems: storedAllItems,
                ownUserId: ownUserId,
                calendar: calendar
            )
            .filter { item in
                guard let sentThanks = item.sentThanks(ownUserId: ownUserId) else { return true }
                guard let keepingSentSince else { return false }
                return sentThanks.sentAt >= keepingSentSince
            }
            notSentItems += items.filter { $0.sentThanks(ownUserId: ownUserId) == nil }
            return items.isEmpty ? nil : .init(date: day, items: items)
        }

        return .init(
            dailyItems: dailyItems,
            notSentCount: notSentItems.count,
            executorNames: ThanksPromptSummary.executorNames(of: notSentItems, members: members, ownUserId: ownUserId)
        )
    }

}
