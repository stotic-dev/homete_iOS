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
    /// 家事ポイント（頑張り度で上乗せする前）
    public let point: Int
    /// 家事ステータス
    public let state: HouseworkState
    /// 担当者（完了していない家事では空）
    ///
    /// 担当者ごとのポイントは上乗せ後のポイント（`earnedPoint`）を配分したもので、合計は`point`ではなく
    /// `earnedPoint`と一致する。
    public let executors: [HouseworkExecutor]
    /// 頑張り度（完了していない家事では`.normal`）
    public let effort: HouseworkEffort
    /// 実行日時
    public let executedAt: Date?
    /// 有効期限
    public let expiredAt: Date
    /// 紐づくテンプレートの家事ID
    public let templateHouseworkItemId: HouseworkTemplateItem.ItemId?
    /// 届いたありがとう（キーは送った人のユーザID）
    public let thanks: [String: HouseworkThanks]
    /// ドキュメントを作った日時。家事の並び順を固定するのに使う
    ///
    /// 作成日時の記録を始める前に作られた家事と、旧バージョンのアプリが上書きした家事は`nil`（ADR-0025）。
    public let createdAt: Date?

    public init(
        id: String,
        indexedDate: HouseworkIndexedDate,
        title: String,
        point: Int,
        state: HouseworkState,
        executors: [HouseworkExecutor],
        effort: HouseworkEffort,
        executedAt: Date?,
        expiredAt: Date,
        templateHouseworkItemId: HouseworkTemplateItem.ItemId?,
        thanks: [String: HouseworkThanks] = [:],
        createdAt: Date? = nil
    ) {
        self.id = id
        self.indexedDate = indexedDate
        self.title = title
        self.point = point
        self.state = state
        self.executors = executors
        self.effort = effort
        self.executedAt = executedAt
        self.expiredAt = expiredAt
        self.templateHouseworkItemId = templateHouseworkItemId
        self.thanks = thanks
        self.createdAt = createdAt
    }

    /// 完了にする
    ///
    /// ありがとうは1回の完了に対して届くものなので、前の完了の記録は引き継がない。
    /// 未完了に戻した直後に、まだ完了表示のままだった同居人の端末からありがとうが書き込まれる
    /// こともあるため、未完了に戻すときだけでなく完了にするときにも消す。
    /// - Parameter executors: 担当者。ポイントは`effort`で上乗せした後のポイントを配分したもの
    public func updateCompleted(
        at now: Date,
        executors: [HouseworkExecutor],
        effort: HouseworkEffort
    ) -> Self {
        // 担当者のポイントの合計は、頑張り度で上乗せした後のポイントと一致させる（ADR-0024）。
        // 配分と頑張り度を別々に受け取るため、組み合わせを取り違えたときに開発中に気付けるようにする
        assert(
            executors.reduce(0) { $0 + $1.point } == effort.boostedPoint(point),
            "担当者のポイントの合計が、頑張り度で上乗せした後のポイントと一致しません"
        )
        return .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .completed,
            executors: executors,
            effort: effort,
            executedAt: now,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId,
            createdAt: createdAt
        )
    }

    /// 同じ家事をもう一度やったものとして、完了済みの別の家事を作る
    ///
    /// 元の家事の完了記録は残したまま、実施した回数分のポイントを積めるように別IDの家事として作る。
    /// テンプレートIDは、その日にテンプレートから生成された1件の家事であることを表すため引き継がない。
    /// 頑張り度を選ぶ画面を通らないため、頑張り度は「ふつう」にする。
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
            templateHouseworkItemId: nil,
            createdAt: now
        )
    }

    /// 未完了に戻す
    ///
    /// 完了を取り消すので、その完了に届いたありがとうの記録も消す。
    public func updateIncomplete() -> Self {
        .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .incomplete,
            executors: [],
            effort: .normal,
            executedAt: nil,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId,
            createdAt: createdAt
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
            effort: effort,
            executedAt: executedAt,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId,
            thanks: thanks,
            createdAt: createdAt
        )
    }

    /// 新しくドキュメントを作る家事に、作成日時を付ける
    public func updateCreatedAt(_ now: Date) -> Self {
        .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: state,
            executors: executors,
            effort: effort,
            executedAt: executedAt,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId,
            thanks: thanks,
            createdAt: now
        )
    }

}

public extension HouseworkItem {

    /// 頑張り度で上乗せした後のポイント。表示にはこちらを使う
    ///
    /// 担当者がいる家事では、担当者のポイントの合計を返す。集計は`executors[].point`を足しているため、
    /// 表示も同じ値から求めて画面ごとに食い違わないようにする。`effort`から計算しないのは、
    /// 保存された`effort`が上乗せ後の配分と対応しなくなる場合があるため（ADR-0024）。
    /// - 旧バージョンのアプリが上書きして`effort`だけが消えた
    /// - 新しいアプリが保存した知らない頑張り度を「ふつう」として読んだ
    var earnedPoint: Int {
        guard !executors.isEmpty else { return effort.boostedPoint(point) }

        return executors.reduce(0) { $0 + $1.point }
    }

    /// 旧バージョンのアプリ向けに保存する実行者のユーザーID（1人目の担当者）
    var executorId: String? {
        executors.first?.userId
    }

    /// 担当者が1人（ポイントを満額配分）で、頑張り度が「ふつう」の家事を作る
    init(
        id: String,
        indexedDate: HouseworkIndexedDate,
        title: String,
        point: Int,
        state: HouseworkState,
        executorId: String?,
        executedAt: Date?,
        expiredAt: Date,
        templateHouseworkItemId: HouseworkTemplateItem.ItemId?,
        thanks: [String: HouseworkThanks] = [:],
        createdAt: Date? = nil
    ) {
        self.init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: state,
            executors: executorId.map { [.solo(userId: $0, point: point)] } ?? [],
            effort: .normal,
            executedAt: executedAt,
            expiredAt: expiredAt,
            templateHouseworkItemId: templateHouseworkItemId,
            thanks: thanks,
            createdAt: createdAt
        )
    }

}

// MARK: - Codable

public extension HouseworkItem {

    internal enum CodingKeys: String, CodingKey {

        case id
        case indexedDate
        case title
        case point
        case state
        case executors
        case effort
        case executorId
        case executedAt
        case expiredAt
        case templateHouseworkItemId
        case thanks
        case createdAt

    }

    /// 担当者を複数持てるようにする前・頑張り度を選べるようにする前のドキュメントも読めるようにするデコード
    ///
    /// `executors`が無いドキュメント（旧バージョンのアプリが書いたもの）は、`executorId`の人に
    /// ポイントを満額配分したものとして読む。旧アプリは`setData(merge: false)`で全体を上書きするため、
    /// 新しいアプリが書いた家事でも、旧アプリが更新すると`executors`が消える（ADR-0023）。
    /// `effort`が無いドキュメントも同じ理由で起こり得るため、「ふつう」として読む（ADR-0024）。
    /// ありがとうの記録が導入される前に保存された家事は`thanks`を持たないため、無ければ空として読む（ADR-0025）。
    /// 作成日時の記録を始める前に保存された家事は`createdAt`を持たないため、`nil`として読む（ADR-0026）。
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let point = try container.decode(Int.self, forKey: .point)
        let executors = try container.decodeIfPresent([HouseworkExecutor].self, forKey: .executors)
        let legacyExecutorId = try container.decodeIfPresent(String.self, forKey: .executorId)

        try self.init(
            id: container.decode(String.self, forKey: .id),
            indexedDate: container.decode(HouseworkIndexedDate.self, forKey: .indexedDate),
            title: container.decode(String.self, forKey: .title),
            point: point,
            state: container.decode(HouseworkState.self, forKey: .state),
            executors: executors ?? legacyExecutorId.map { [.solo(userId: $0, point: point)] } ?? [],
            effort: container.decodeIfPresent(HouseworkEffort.self, forKey: .effort) ?? .normal,
            executedAt: container.decodeIfPresent(Date.self, forKey: .executedAt),
            expiredAt: container.decode(Date.self, forKey: .expiredAt),
            templateHouseworkItemId: container.decodeIfPresent(
                HouseworkTemplateItem.ItemId.self,
                forKey: .templateHouseworkItemId
            ),
            thanks: container.decodeIfPresent([String: HouseworkThanks].self, forKey: .thanks) ?? [:],
            createdAt: container.decodeIfPresent(Date.self, forKey: .createdAt)
        )
    }

    /// 旧バージョンのアプリが実行者を読めるよう、`executorId`に1人目の担当者も書く
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(indexedDate, forKey: .indexedDate)
        try container.encode(title, forKey: .title)
        try container.encode(point, forKey: .point)
        try container.encode(state, forKey: .state)
        try container.encode(executors, forKey: .executors)
        try container.encode(effort, forKey: .effort)
        try container.encodeIfPresent(executorId, forKey: .executorId)
        try container.encodeIfPresent(executedAt, forKey: .executedAt)
        try container.encode(expiredAt, forKey: .expiredAt)
        try container.encodeIfPresent(templateHouseworkItemId, forKey: .templateHouseworkItemId)
        try container.encode(thanks, forKey: .thanks)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
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
        templateHouseworkItemId: HouseworkTemplateItem.ItemId? = nil,
        thanks: [String: HouseworkThanks] = [:]
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
            templateHouseworkItemId: templateHouseworkItemId,
            thanks: thanks
        )
    }

}
