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
    /// 届いたありがとう（送られた順）
    public let thanks: [HouseworkThanks]

    public init(
        id: String,
        indexedDate: HouseworkIndexedDate,
        title: String,
        point: Int,
        state: HouseworkState,
        executorId: String?,
        executedAt: Date?,
        expiredAt: Date,
        templateHouseworkItemId: HouseworkTemplateItem.ItemId?,
        thanks: [HouseworkThanks] = []
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
        self.thanks = thanks
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
            templateHouseworkItemId: templateHouseworkItemId,
            thanks: thanks
        )
    }

    /// 同じ家事をもう一度やったものとして、完了済みの別の家事を作る
    ///
    /// 元の家事の完了記録は残したまま、実施した回数分のポイントを積めるように別IDの家事として作る。
    /// テンプレートIDは、その日にテンプレートから生成された1件の家事であることを表すため引き継がない。
    public func makeRedone(id: String, at now: Date, executor: String) -> Self {
        .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .completed,
            executorId: executor,
            executedAt: now,
            expiredAt: expiredAt,
            templateHouseworkItemId: nil
        )
    }

    /// 未完了に戻す
    ///
    /// 完了そのものを取り消すため、完了に対して届いたありがとうも残さない。
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

    /// ありがとうを追加する
    public func addingThanks(_ newThanks: HouseworkThanks) -> Self {
        .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: state,
            executorId: executorId,
            executedAt: executedAt,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId,
            thanks: thanks + [newThanks]
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
            templateHouseworkItemId: templateHouseworkItemId,
            thanks: thanks
        )
    }

}

extension HouseworkItem {

    private enum CodingKeys: String, CodingKey {

        case id
        case indexedDate
        case title
        case point
        case state
        case executorId
        case executedAt
        case expiredAt
        case templateHouseworkItemId
        case thanks

    }

    /// ありがとうを保存する前に登録された家事には`thanks`が無いため、無ければ空として読む
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(String.self, forKey: .id),
            indexedDate: container.decode(HouseworkIndexedDate.self, forKey: .indexedDate),
            title: container.decode(String.self, forKey: .title),
            point: container.decode(Int.self, forKey: .point),
            state: container.decode(HouseworkState.self, forKey: .state),
            executorId: container.decodeIfPresent(String.self, forKey: .executorId),
            executedAt: container.decodeIfPresent(Date.self, forKey: .executedAt),
            expiredAt: container.decode(Date.self, forKey: .expiredAt),
            templateHouseworkItemId: container.decodeIfPresent(
                HouseworkTemplateItem.ItemId.self,
                forKey: .templateHouseworkItemId
            ),
            thanks: container.decodeIfPresent([HouseworkThanks].self, forKey: .thanks) ?? []
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
