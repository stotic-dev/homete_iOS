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

    public var point: Int {
        originalItem.point
    }

    public var executorId: String? {
        originalItem.executorId
    }

    public var executedAt: Date? {
        originalItem.executedAt
    }

    /// 自分が終えた家事かどうか
    public func isExecutedBy(_ userId: String) -> Bool {
        originalItem.executorId == userId
    }

    /// 自分が送ったありがとう。まだ送っていなければ`nil`
    public func sentThanks(ownUserId: String) -> HouseworkThanks? {
        originalItem.thanks[ownUserId]
    }

    /// ありがとうを伝えられるかどうか
    ///
    /// 自分が終えた家事に自分でありがとうを送っても意味がないため、実施者本人には送らせない。
    /// 1人が1つの家事に送れるのは1回までで、送った後はコメントの編集だけできる。
    public func canSendThanks(ownUserId: String) -> Bool {
        state == .completed && !isExecutedBy(ownUserId) && sentThanks(ownUserId: ownUserId) == nil
    }

    /// 送ったありがとうのコメントを編集できるかどうか
    public func canEditThanks(ownUserId: String) -> Bool {
        state == .completed && !isExecutedBy(ownUserId) && sentThanks(ownUserId: ownUserId) != nil
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
