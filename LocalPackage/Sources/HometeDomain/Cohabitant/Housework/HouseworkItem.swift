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
    /// 有効期限
    public let expiredAt: Date
    /// 紐づくテンプレートの家事ID
    public let templateHouseworkItemId: HouseworkTemplateItem.ItemId?

    public init(
        id: String,
        indexedDate: HouseworkIndexedDate,
        title: String,
        point: Int,
        state: HouseworkState,
        executorId: String?,
        executedAt: Date?,
        expiredAt: Date,
        templateHouseworkItemId: HouseworkTemplateItem.ItemId?
    ) {
        self.id = id
        self.indexedDate = indexedDate
        self.title = title
        self.point = point
        self.state = state
        self.executorId = executorId
        self.executedAt = executedAt
        self.expiredAt = expiredAt
        self.templateHouseworkItemId = templateHouseworkItemId
    }

    public func updateCompleted(at now: Date, executor: String) -> Self {
        .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .completed,
            executorId: executor,
            executedAt: now,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId
        )
    }

    public func updateIncomplete() -> Self {
        .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .incomplete,
            executorId: nil,
            executedAt: nil,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId
        )
    }

    public func updateNotTodo() -> Self {
        .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .notTodo,
            executorId: executorId,
            executedAt: executedAt,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId
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
        templateHouseworkItemId: HouseworkTemplateItem.ItemId? = nil
    ) {
        self.init(
            id: id,
            indexedDate: metaData.indexedDate,
            title: title,
            point: point,
            state: state,
            executorId: executorId,
            executedAt: executedAt,
            expiredAt: metaData.expiredAt,
            templateHouseworkItemId: templateHouseworkItemId
        )
    }

}
