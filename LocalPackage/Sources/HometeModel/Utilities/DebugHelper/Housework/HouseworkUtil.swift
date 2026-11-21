//
//  HouseworkUtil.swift
//  homete
//
//  Created by Taichi Sato on 2026/01/12.
//

import Foundation

#if DEBUG

public extension HouseworkItem {

    static func makeForPreview(
        id: String = UUID().uuidString,
        title: String = "",
        point: Int = 10,
        indexedDate: HouseworkIndexedDate = .init(value: .previewDate(year: 2026, month: 1, day: 1)),
        state: HouseworkState = .incomplete,
        executorId: String? = nil,
        executors: [HouseworkExecutor] = [],
        effort: HouseworkEffort = .normal,
        executedAt: Date? = nil,
        thanks: [String: HouseworkThanks] = [:],
        memo: HouseworkMemo? = nil,
        postponedFrom: HouseworkIndexedDate? = nil,
        images: [HouseworkImage]? = nil // swiftlint:disable:this discouraged_optional_collection
    ) -> Self {
        .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: state,
            executors: executorId.map { [.solo(userId: $0, point: effort.boostedPoint(point))] } ?? executors,
            effort: effort,
            executedAt: executedAt,
            templateHouseworkItemId: nil,
            thanks: thanks,
            memo: memo,
            postponedFrom: postponedFrom,
            images: images
        )
    }

}

public extension HouseworkBoardItem {

    static func makeForPreview(
        id: String = UUID().uuidString,
        title: String = "",
        point: Int = 10,
        indexedDate: HouseworkIndexedDate = .init(value: .previewDate(year: 2026, month: 1, day: 1)),
        state: HouseworkState = .incomplete,
        executorId: String? = nil,
        executors: [HouseworkExecutor] = [],
        effort: HouseworkEffort = .normal,
        executedAt: Date? = nil,
        thanks: [String: HouseworkThanks] = [:],
        memo: HouseworkMemo? = nil,
        postponedFrom: HouseworkIndexedDate? = nil,
        images: [HouseworkImage]? = nil, // swiftlint:disable:this discouraged_optional_collection
        isRegistered: Bool = true
    ) -> Self {
        .init(
            originalItem: .makeForPreview(
                id: id,
                title: title,
                point: point,
                indexedDate: indexedDate,
                state: state,
                executorId: executorId,
                executors: executors,
                effort: effort,
                executedAt: executedAt,
                thanks: thanks,
                memo: memo,
                postponedFrom: postponedFrom,
                images: images
            ),
            isRegistered: isRegistered
        )
    }

}

#endif
