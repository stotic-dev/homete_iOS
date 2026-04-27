//
//  HouseworkItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation

public struct HouseworkItem: Identifiable, Equatable, Sendable, Hashable, Codable {

    public let id: String
    /// 家事の日付情報
    public let indexedDate: HouseworkIndexedDate
    /// 家事のタイトル
    public let title: String
    /// 家事ポイント
    public let point: Int
    /// 家事ステータス
    public let state: HouseworkState
    /// 実行者のユーザID
    public let executorId: String?
    /// 実行日時
    public let executedAt: Date?
    /// 確認者のユーザID
    public let reviewerId: String?
    /// 承認日時
    public let approvedAt: Date?
    /// 確認コメント
    public let reviewerComment: String?
    /// 有効期限
    public let expiredAt: Date

    public init(
        id: String,
        indexedDate: HouseworkIndexedDate,
        title: String,
        point: Int,
        state: HouseworkState,
        executorId: String?,
        executedAt: Date?,
        reviewerId: String?,
        approvedAt: Date?,
        reviewerComment: String?,
        expiredAt: Date
    ) {
        self.id = id
        self.indexedDate = indexedDate
        self.title = title
        self.point = point
        self.state = state
        self.executorId = executorId
        self.executedAt = executedAt
        self.reviewerId = reviewerId
        self.approvedAt = approvedAt
        self.reviewerComment = reviewerComment
        self.expiredAt = expiredAt
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
        return indexedDate.value.formatted(formatStyle)
    }

    /// レビュー可能かどうか
    public func canReview(ownUserId: String) -> Bool {

        return executorId != ownUserId && state != .completed
    }

    public func updatePendingApproval(at now: Date, changer: String) -> Self {

        return .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .pendingApproval,
            executorId: changer,
            executedAt: now,
            reviewerId: reviewerId,
            approvedAt: approvedAt,
            reviewerComment: reviewerComment,
            expiredAt: expiredAt
        )
    }

    public func updateApproved(at now: Date, reviewer: String, comment: String) -> Self {

        return .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .completed,
            executorId: executorId,
            executedAt: executedAt,
            reviewerId: reviewer,
            approvedAt: now,
            reviewerComment: comment,
            expiredAt: expiredAt
        )
    }

    public func updateRejected(at now: Date, reviewer: String, comment: String) -> Self {

        return .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .incomplete,
            executorId: executorId,
            executedAt: executedAt,
            reviewerId: reviewer,
            approvedAt: now,
            reviewerComment: comment,
            expiredAt: expiredAt
        )
    }

    public func updateIncomplete() -> Self {

        return .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .incomplete,
            executorId: nil,
            executedAt: nil,
            reviewerId: nil,
            approvedAt: nil,
            reviewerComment: nil,
            expiredAt: expiredAt
        )
    }
}

public extension HouseworkItem {

    init(
        id: String,
        title: String,
        point: Int,
        metaData: DailyHouseworkMetaData,
        state: HouseworkState = .incomplete,
        executorId: String? = nil,
        executedAt: Date? = nil,
        reviewerId: String? = nil,
        approvedAt: Date? = nil,
        reviewerComment: String? = nil
    ) {

        self.init(
            id: id,
            indexedDate: metaData.indexedDate,
            title: title,
            point: point,
            state: state,
            executorId: executorId,
            executedAt: executedAt,
            reviewerId: reviewerId,
            approvedAt: approvedAt,
            reviewerComment: reviewerComment,
            expiredAt: metaData.expiredAt
        )
    }
}
