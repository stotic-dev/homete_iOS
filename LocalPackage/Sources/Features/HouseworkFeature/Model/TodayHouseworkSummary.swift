//
//  TodayHouseworkSummary.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import Foundation
import HometeDomain

/// 当日の家事サマリー（進捗・未完了一覧・表示状態）
public struct TodayHouseworkSummary: Equatable, Sendable {

    /// サマリーに表示する未完了家事の最大件数
    public static let displayIncompleteLimit = 4

    /// 当日の全家事
    public let allItems: [HouseworkItem]
    /// 未完了家事（`incomplete` + `pendingApproval`）
    public let incompleteItems: [HouseworkItem]
    /// 達成率（0.0〜1.0）。家事が0件のときは0
    public let progress: Double
    /// 表示状態
    public let displayState: DisplayState
    /// サマリーに表示する未完了家事（最大 `displayIncompleteLimit` 件）
    public let displayIncompleteItems: [HouseworkItem]
    /// 未完了家事が表示上限を超えるか
    public let hasMoreIncomplete: Bool

}

public extension TodayHouseworkSummary {

    static func make(storedAllItems: StoredAllHouseworkList, now: Date, calendar: Calendar) -> Self {
        let today = calendar.startOfDay(for: now)
        let allItems = storedAllItems.value
            .first { $0.metaData.indexedDate.value == today }?
            .items ?? []

        let incomplete = allItems.filter { item in
            item.state == .incomplete || item.state == .pendingApproval
        }

        let progress: Double
        let displayState: DisplayState
        if allItems.isEmpty {
            progress = 0
            displayState = .empty
        } else {
            let completedCount = allItems.count - incomplete.count
            progress = Double(completedCount) / Double(allItems.count)
            displayState = incomplete.isEmpty ? .allCompleted : .hasIncomplete
        }

        let displayIncompleteItems = Array(incomplete.prefix(Self.displayIncompleteLimit))
        let hasMoreIncomplete = incomplete.count > Self.displayIncompleteLimit

        return .init(
            allItems: allItems,
            incompleteItems: incomplete,
            progress: progress,
            displayState: displayState,
            displayIncompleteItems: displayIncompleteItems,
            hasMoreIncomplete: hasMoreIncomplete
        )
    }

}

public extension TodayHouseworkSummary {

    /// サマリーの表示状態
    enum DisplayState: Equatable, Sendable {

        /// 当日の家事が0件
        case empty
        /// 全ての家事が完了
        case allCompleted
        /// 未完了の家事がある
        case hasIncomplete

    }

}
