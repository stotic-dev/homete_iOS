//
//  HouseworkTemplateAnalyticsAction.swift
//  LocalPackage
//

/// 家事テンプレートに関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `housework_template`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum HouseworkTemplateAnalyticsAction: Equatable, Sendable {

    /// テンプレートを初めて作成した
    case apply(isSuccess: Bool)
    /// テンプレートに家事を追加した
    /// - Note: 保存時にドラフトとの差分から検出するため、追加された家事1件ごとに1イベント送る
    case create(isSuccess: Bool)
    /// テンプレートの家事を編集した
    /// - Note: 保存時にドラフトとの差分から検出するため、編集された家事1件ごとに1イベント送る
    case edit(isSuccess: Bool)
    /// テンプレートの家事を削除した
    /// - Note: 保存時にドラフトとの差分から検出するため、削除された家事1件ごとに1イベント送る
    case delete(isSuccess: Bool)

}

extension HouseworkTemplateAnalyticsAction {

    /// `housework_template`イベントに載せるパラメータ
    /// - Note: `action`は全ケースで送り、`result`はGA上でそのまま読める値にするため真偽値ではなく意味のある文字列にする
    var parameters: [String: String] {
        ["action": action, "result": result]
    }

}

private extension HouseworkTemplateAnalyticsAction {

    var action: String {
        switch self {
        case .apply:
            "apply"

        case .create:
            "create"

        case .edit:
            "edit"

        case .delete:
            "delete"
        }
    }

    var result: String {
        switch self {
        case let .apply(isSuccess),
             let .create(isSuccess),
             let .edit(isSuccess),
             let .delete(isSuccess):
            isSuccess ? "success" : "failure"
        }
    }

}
