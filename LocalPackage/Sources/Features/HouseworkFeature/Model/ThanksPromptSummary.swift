//
//  ThanksPromptSummary.swift
//  LocalPackage
//

import Foundation
import HometeDomain

/// 同居人がやってくれた家事のうち、ありがとうを伝えられるもの
///
/// ダッシュボードの感謝の促しと、ありがとうを伝えられる家事の一覧で使う。
/// 同居人が夜遅くにやった家事に翌朝も気づけるよう、今日と昨日の家事を対象にする。
public struct ThanksPromptSummary: Equatable, Sendable {

    /// ありがとうを伝えられる家事（まだ送っていない → 送った、の順。それぞれ完了日時の新しい順）
    public let thankableItems: [HouseworkBoardItem]
    /// まだありがとうを送っていない件数
    public let notSentCount: Int
    /// まだありがとうを送っていない家事を担当した、自分以外のメンバーの名前（メンバー一覧の順）
    public let executorNames: [String]

    public init(thankableItems: [HouseworkBoardItem], notSentCount: Int, executorNames: [String]) {
        self.thankableItems = thankableItems
        self.notSentCount = notSentCount
        self.executorNames = executorNames
    }

    /// 感謝の促しを出すかどうか
    public var shouldPrompt: Bool {
        notSentCount > 0
    }

}

public extension ThanksPromptSummary {

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
        let targetDays: Set<Date> = [today, yesterday]

        let thankableItems = storedAllItems.value
            .filter { targetDays.contains(calendar.startOfDay(for: $0.metaData.indexedDate.value)) }
            .flatMap(\.items)
            .map { HouseworkBoardItem(originalItem: $0, isRegistered: true) }
            .filter { $0.isThankable(by: ownUserId) }
            .sorted { isOrderedBefore($0, $1, ownUserId: ownUserId) }
        let notSentItems = thankableItems.filter { $0.sentThanks(ownUserId: ownUserId) == nil }
        let notSentExecutorIds = Set(notSentItems.flatMap(\.executors).map(\.userId))

        return .init(
            thankableItems: thankableItems,
            notSentCount: notSentItems.count,
            executorNames: members.others
                .filter { $0.id != ownUserId && notSentExecutorIds.contains($0.id) }
                .map(\.userName)
        )
    }

}

private extension ThanksPromptSummary {

    /// まだ送っていない家事を先に、その中では完了日時の新しい順に並べる
    static func isOrderedBefore(_ lhs: HouseworkBoardItem, _ rhs: HouseworkBoardItem, ownUserId: String) -> Bool {
        let lhsSent = lhs.sentThanks(ownUserId: ownUserId) != nil
        let rhsSent = rhs.sentThanks(ownUserId: ownUserId) != nil
        if lhsSent != rhsSent {
            return !lhsSent
        }
        let lhsExecutedAt = lhs.executedAt ?? .distantPast
        let rhsExecutedAt = rhs.executedAt ?? .distantPast
        if lhsExecutedAt != rhsExecutedAt {
            return lhsExecutedAt > rhsExecutedAt
        }
        return lhs.id < rhs.id
    }

}
