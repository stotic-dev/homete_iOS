//
//  HouseworkItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation

struct HouseworkItem: Identifiable, Equatable, Sendable, Hashable, Codable {
    
    let id: String
    /// 家事の日付情報
    let indexedDate: HouseworkIndexedDate
    /// 家事のタイトル
    let title: String
    /// 家事ポイント
    let point: Int
    /// 家事ステータス
    let state: HouseworkState
    /// 実行者のユーザID
    let executorId: String?
    /// 実行日時
    let executedAt: Date?
    /// 確認者のユーザID
    let reviewerId: String?
    /// 承認日時
    let approvedAt: Date?
    /// 確認コメント
    let reviewerComment: String?
    /// 有効期限
    let expiredAt: Date
    
    var formattedIndexedDate: String {
        
        return indexedDate.value
    }
    
    func updatePendingApproval(at now: Date, changer: String) -> Self {
        
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
    
    func updateApproved(at now: Date, reviewer: String, comment: String) -> Self {
        
        return .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .pendingApproval,
            executorId: executorId,
            executedAt: executedAt,
            reviewerId: reviewer,
            approvedAt: now,
            reviewerComment: comment,
            expiredAt: expiredAt
        )
    }
    
    func updateIncomplete() -> Self {
        
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
    
    func isApprovable(_ userId: String) -> Bool {
        
        guard let executorId else { return false }
        return executorId != userId
    }
}

extension HouseworkItem {
    
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
