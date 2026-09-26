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

    /// ありがとうを伝えられるかどうか
    ///
    /// 自分が終えた家事に自分でありがとうを送っても意味がないため、実施者本人には送らせない。
    public func canSendThanks(ownUserId: String) -> Bool {
        state == .completed && originalItem.executorId != ownUserId
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
