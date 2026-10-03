//
//  HouseworkBoardItem.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/20.
//

import Foundation
import HometeDomain

public struct HouseworkBoardItem: Equatable, Identifiable, Hashable, Sendable {

    public let originalItem: HouseworkItem
    public let isRegistered: Bool

    public init(originalItem: HouseworkItem, isRegistered: Bool) {
        self.originalItem = originalItem
        self.isRegistered = isRegistered
    }

    public var id: String {
        originalItem.id
    }

    public var title: String {
        originalItem.title
    }

    public var state: HouseworkState {
        originalItem.state
    }

    /// 表示するポイント（頑張り度で上乗せした後）
    ///
    /// 上乗せ前のポイントは`originalItem.point`で参照する。
    public var earnedPoint: Int {
        originalItem.earnedPoint
    }

    public var effort: HouseworkEffort {
        originalItem.effort
    }

    public var executedAt: Date? {
        originalItem.executedAt
    }

    public var executors: [HouseworkExecutor] {
        originalItem.executors
    }

    /// 担当者に含まれているかどうか
    public func isExecutedBy(_ userId: String) -> Bool {
        executors.contains { $0.userId == userId }
    }

    /// 自分が送ったありがとう。まだ送っていなければ`nil`
    public func sentThanks(ownUserId: String) -> HouseworkThanks? {
        originalItem.thanks[ownUserId]
    }

    /// ありがとうを伝えられるかどうか
    ///
    /// 自分が終えた家事に自分でありがとうを送っても意味がないため、担当者に自分以外が含まれるときだけ送れる。
    /// 複数人で手分けした家事なら、自分が担当者に含まれていても他の担当者へ送れる。
    /// 1人が1つの家事に送れるのは1回までで、送った後はコメントの編集だけできる。
    public func canSendThanks(ownUserId: String) -> Bool {
        isThankable(by: ownUserId) && sentThanks(ownUserId: ownUserId) == nil
    }

    /// 送ったありがとうのコメントを編集できるかどうか
    public func canEditThanks(ownUserId: String) -> Bool {
        isThankable(by: ownUserId) && sentThanks(ownUserId: ownUserId) != nil
    }

    /// 完了済みで、担当者に自分以外が含まれているかどうか
    public func isThankable(by ownUserId: String) -> Bool {
        state == .completed && executors.contains { $0.userId != ownUserId }
    }

    /// 手伝った人を足せるかどうか
    ///
    /// 完了済みで、まだ担当者になっていないメンバーがいて、人数の上限にも達していないときだけ足せる。
    /// 足せないときは「手伝った人を追加」の導線を出さない。
    public func canAddHelper(members: CohabitantMemberList) -> Bool {
        guard state == .completed else { return false }

        return HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: members.value.map(\.id),
            executors: executors,
            earnedPoint: earnedPoint
        )
        .canAddExecutor
    }

    public func formattedIndexedDate(calendar: Calendar) -> String {
        let formatStyle = Date.FormatStyle(
            date: .numeric,
            time: .omitted,
            locale: calendar.locale ?? .autoupdatingCurrent,
            calendar: calendar,
            timeZone: calendar.timeZone
        )
        .year(.extended(minimumLength: 4))
        .month(.twoDigits)
        .day(.twoDigits)
        return originalItem.indexedDate.value.formatted(formatStyle)
    }

}
