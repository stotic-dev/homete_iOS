//
//  HouseworkUtil.swift
//  homete
//
//  Created by Taichi Sato on 2026/01/12.
//

import Foundation
import HometeDomain

#if DEBUG

extension HouseworkItem {

    static func makeForPreview(
        id: String = UUID().uuidString,
        title: String = "",
        point: Int = 10,
        indexedDate: HouseworkIndexedDate = .init(value: .previewDate(year: 2026, month: 1, day: 1)),
        expiredAt: Date = .distantFuture,
        state: HouseworkState = .incomplete,
        executorId: String? = nil,
        executedAt: Date? = nil
    ) -> Self {
        .init(
            id: id,
            title: title,
            point: point,
            metaData: .init(indexedDate: indexedDate, expiredAt: expiredAt),
            state: state,
            executorId: executorId,
            executedAt: executedAt
        )
    }

}

extension HouseworkBoardItem {

    static func makeForPreview(
        id: String = UUID().uuidString,
        title: String = "",
        point: Int = 10,
        indexedDate: HouseworkIndexedDate = .init(value: .previewDate(year: 2026, month: 1, day: 1)),
        expiredAt: Date = .distantFuture,
        state: HouseworkState = .incomplete,
        executorId: String? = nil,
        executedAt: Date? = nil,
        isRegistered: Bool = true
    ) -> Self {
        .init(
            originalItem: .makeForPreview(
                id: id,
                title: title,
                point: point,
                indexedDate: indexedDate,
                expiredAt: expiredAt,
                state: state,
                executorId: executorId,
                executedAt: executedAt
            ),
            isRegistered: isRegistered
        )
    }

}

#endif
