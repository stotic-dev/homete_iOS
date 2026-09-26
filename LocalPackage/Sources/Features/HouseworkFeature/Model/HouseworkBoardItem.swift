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

    public var executedAt: Date? {
        originalItem.executedAt
    }

    public var executors: [HouseworkExecutor] {
        originalItem.executors
    }

    /// ありがとうを伝えられるかどうか
    ///
    /// 自分が終えた家事に自分でありがとうを送っても意味がないため、担当者に自分以外が含まれるときだけ送れる。
    /// 複数人で手分けした家事なら、自分が担当者に含まれていても他の担当者へ送れる。
    public func canSendThanks(ownUserId: String) -> Bool {
        state == .completed && executors.contains { $0.userId != ownUserId }
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
