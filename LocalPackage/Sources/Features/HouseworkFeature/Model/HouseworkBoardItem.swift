//
//  HouseworkBoardItem.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/20.
//

import Foundation
import HometeDomain

struct HouseworkBoardItem: Equatable, Identifiable, Hashable {

    let originalItem: HouseworkItem
    let isRegistered: Bool

    var id: String {
        originalItem.id
    }

    var title: String {
        originalItem.title
    }

    var state: HouseworkState {
        originalItem.state
    }

    var point: Int {
        originalItem.point
    }

    var executorId: String? {
        originalItem.executorId
    }

    var executedAt: Date? {
        originalItem.executedAt
    }

    /// レビュー可能かどうか
    func canReview(ownUserId: String) -> Bool {
        originalItem.executorId != ownUserId && state != .completed
    }

    func formattedIndexedDate(calendar: Calendar) -> String {
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
