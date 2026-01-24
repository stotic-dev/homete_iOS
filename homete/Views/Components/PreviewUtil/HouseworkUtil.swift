//
//  HouseworkUtil.swift
//  homete
//
//  Created by Taichi Sato on 2026/01/12.
//

import Foundation

extension HouseworkItem {
    
    static func makeForPreview(
        id: String = UUID().uuidString,
        title: String = "",
        point: Int = 10,
        indexedDate: HouseworkIndexedDate = .init(value: "2026/01/01"),
        expiredAt: Date = .distantFuture,
        state: HouseworkState = .incomplete,
        executorId: String? = nil,
        executedAt: Date? = nil,
        reviewerId: String? = nil,
        approvedAt: Date? = nil,
        reviewerComment: String? = nil
    ) -> Self {
        
        return .init(
            id: id,
            title: title,
            point: point,
            metaData: .init(indexedDate: indexedDate, expiredAt: expiredAt),
            state: state,
            executorId: executorId,
            executedAt: executedAt,
            reviewerId: reviewerId,
            approvedAt: approvedAt,
            reviewerComment: reviewerComment
        )
    }
}
