//
//  HouseworkItemHelper.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/02.
//

import Foundation

#if DEBUG

public extension HouseworkItem {

    static func makeForTest(
        id: Int,
        indexedDate: Date = .now,
        title: String = "title",
        point: Int = 100,
        state: HouseworkState = .incomplete,
        executorId: String? = nil,
        executedAt: Date? = nil,
        expiredAt: Date = .now,
        templateHouseworkItemId: HouseworkTemplateItem.ItemId? = nil
    ) -> Self {
        .init(
            id: "id\(id.formatted())",
            indexedDate: .init(value: indexedDate),
            title: title,
            point: point,
            state: state,
            executorId: executorId,
            executedAt: executedAt,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId
        )
    }

    static func makeForTest(
        id: String,
        indexedDate: Date = .now,
        title: String = "title",
        point: Int = 100,
        state: HouseworkState = .incomplete,
        executorId: String? = nil,
        executedAt: Date? = nil,
        expiredAt: Date = .now,
        templateHouseworkItemId: HouseworkTemplateItem.ItemId? = nil
    ) -> Self {
        .init(
            id: id,
            indexedDate: .init(value: indexedDate),
            title: title,
            point: point,
            state: state,
            executorId: executorId,
            executedAt: executedAt,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId
        )
    }

    func updateProperties(
        indexedDate: HouseworkIndexedDate? = nil,
        title: String? = nil,
        point: Int? = nil,
        state: HouseworkState? = nil,
        executorId: String? = nil,
        executedAt: Date? = nil,
        expiredAt: Date? = nil,
        templateHouseworkItemId: HouseworkTemplateItem.ItemId? = nil
    ) -> HouseworkItem {
        let inputIndexedDate = indexedDate ?? self.indexedDate
        let inputTitle = title ?? self.title
        let inputPoint = point ?? self.point
        let inputState = state ?? self.state
        let inputExecutorId = executorId
        let inputExecutedAt = executedAt
        let inputExpiredAt = expiredAt ?? self.expiredAt
        let inputTemplateHouseworkItemId = templateHouseworkItemId ?? self.templateHouseworkItemId

        return .init(
            id: id,
            indexedDate: inputIndexedDate,
            title: inputTitle,
            point: inputPoint,
            state: inputState,
            executorId: inputExecutorId,
            executedAt: inputExecutedAt,
            expiredAt: inputExpiredAt,
            templateHouseworkItemId: inputTemplateHouseworkItemId
        )
    }

}

#endif
