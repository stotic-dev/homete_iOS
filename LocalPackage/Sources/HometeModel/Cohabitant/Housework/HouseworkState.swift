//
//  HouseworkState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

public enum HouseworkState: CaseIterable, Identifiable, Codable, Sendable {

    /// 未完了
    case incomplete
    /// 完了
    case completed
    /// やらない
    case notTodo

    public var id: Self {
        self
    }

    enum CodingKeys: String, CodingKey {

        case incomplete
        case completed
        case notTodo

    }

    /// 未知のケースを完了として扱うデコード
    ///
    /// 廃止した承認待ち（`pendingApproval`）のドキュメントがFirestoreに1件でも残っていると、
    /// 素のCodable準拠では家事リスト全体のデコードが失敗して何も表示できなくなる。
    /// 既存データはマイグレーションで完了に書き換える前提だが、実行漏れやアプリの配信タイミングの
    /// ズレでも壊れないよう、知らないケースは完了に寄せる。
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .incomplete:
            self = .incomplete

        case .notTodo:
            self = .notTodo

        // 承認待ちだった家事は実行者が完了報告を済ませているため、完了として扱う
        case .completed, nil:
            self = .completed
        }
    }

}
