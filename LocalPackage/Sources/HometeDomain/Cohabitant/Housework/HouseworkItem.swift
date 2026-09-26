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
    /// 担当者（完了していない家事では空）
    public let executors: [HouseworkExecutor]
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
        executors: [HouseworkExecutor],
        executedAt: Date?,
        expiredAt: Date,
        templateHouseworkItemId: HouseworkTemplateItem.ItemId?
    ) {
        self.id = id
        self.indexedDate = indexedDate
        self.title = title
        self.point = point
        self.state = state
        self.executors = executors
        self.executedAt = executedAt
        self.expiredAt = expiredAt
        self.templateHouseworkItemId = templateHouseworkItemId
    }

    public func updateCompleted(at now: Date, executors: [HouseworkExecutor]) -> Self {
        .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .completed,
            executors: executors,
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
            executors: [],
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
            executors: executors,
            executedAt: executedAt,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId
        )
    }

}

public extension HouseworkItem {

    /// 旧バージョンのアプリ向けに保存する実行者のユーザーID（1人目の担当者）
    var executorId: String? {
        executors.first?.userId
    }

    /// 担当者が1人（ポイントを満額配分）の家事を作る
    init(
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
        self.init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: state,
            executors: executorId.map { [.solo(userId: $0, point: point)] } ?? [],
            executedAt: executedAt,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId
        )
    }

}

// MARK: - Codable

extension HouseworkItem {

    enum CodingKeys: String, CodingKey {

        case id
        case indexedDate
        case title
        case point
        case state
        case executors
        case executorId
        case executedAt
        case expiredAt
        case templateHouseworkItemId

    }

    /// 担当者を複数持てるようにする前のドキュメントも読めるようにするデコード
    ///
    /// `executors`が無いドキュメント（旧バージョンのアプリが書いたもの）は、`executorId`の人に
    /// ポイントを満額配分したものとして読む。旧アプリは`setData(merge: false)`で全体を上書きするため、
    /// 新しいアプリが書いた家事でも、旧アプリが更新すると`executors`が消える（ADR-0022）。
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let point = try container.decode(Int.self, forKey: .point)
        let executors = try container.decodeIfPresent([HouseworkExecutor].self, forKey: .executors)
        let legacyExecutorId = try container.decodeIfPresent(String.self, forKey: .executorId)

        self.init(
            id: try container.decode(String.self, forKey: .id),
            indexedDate: try container.decode(HouseworkIndexedDate.self, forKey: .indexedDate),
            title: try container.decode(String.self, forKey: .title),
            point: point,
            state: try container.decode(HouseworkState.self, forKey: .state),
            executors: executors ?? legacyExecutorId.map { [.solo(userId: $0, point: point)] } ?? [],
            executedAt: try container.decodeIfPresent(Date.self, forKey: .executedAt),
            expiredAt: try container.decode(Date.self, forKey: .expiredAt),
            templateHouseworkItemId: try container.decodeIfPresent(
                HouseworkTemplateItem.ItemId.self,
                forKey: .templateHouseworkItemId
            )
        )
    }

    /// 旧バージョンのアプリが実行者を読めるよう、`executorId`に1人目の担当者も書く
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(indexedDate, forKey: .indexedDate)
        try container.encode(title, forKey: .title)
        try container.encode(point, forKey: .point)
        try container.encode(state, forKey: .state)
        try container.encode(executors, forKey: .executors)
        try container.encodeIfPresent(executorId, forKey: .executorId)
        try container.encodeIfPresent(executedAt, forKey: .executedAt)
        try container.encode(expiredAt, forKey: .expiredAt)
        try container.encodeIfPresent(templateHouseworkItemId, forKey: .templateHouseworkItemId)
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
