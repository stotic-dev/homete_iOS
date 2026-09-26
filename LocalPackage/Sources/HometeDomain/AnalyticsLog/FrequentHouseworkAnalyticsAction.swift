//
//  FrequentHouseworkAnalyticsAction.swift
//  LocalPackage
//

/// いつもの家事に関する行動の起点画面
public enum FrequentHouseworkAnalyticsStep: String, Equatable, Sendable {

    /// いつもの家事の管理画面
    case management
    /// 家事の登録シート（「いつもの家事に保存する」）
    case register
    /// テンプレートの家事追加モーダル（「いつもの家事に保存する」）
    case template

}

/// いつもの家事に関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `frequent_housework`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum FrequentHouseworkAnalyticsAction: Equatable, Sendable {

    /// いつもの家事を追加した
    /// - Note: 追加された家事1件ごとに1イベント送る
    case create(step: FrequentHouseworkAnalyticsStep, isSuccess: Bool)
    /// いつもの家事を編集した
    case edit(isSuccess: Bool)
    /// いつもの家事を削除した
    case delete(isSuccess: Bool)
    /// テンプレートから取り込んだ
    /// - Note: 取り込み1回につき1イベント送る
    case importFromTemplate(isSuccess: Bool)
    /// 無料プランの上限の案内を表示した
    case limitReached(step: FrequentHouseworkAnalyticsStep)
    /// カスタムカテゴリを追加した
    case createCategory(isSuccess: Bool)
    /// カスタムカテゴリの名前を変更した
    case editCategory(isSuccess: Bool)
    /// カスタムカテゴリを削除した
    case deleteCategory(isSuccess: Bool)

}

extension FrequentHouseworkAnalyticsAction {

    /// `frequent_housework`イベントに載せるパラメータ
    /// - Note: `action`は全ケースで送り、`step`と`result`はそれぞれ意味を持つケースのみ追加する
    var parameters: [String: String] {
        var parameters = ["action": action]
        if let step {
            parameters["step"] = step
        }
        if let result {
            parameters["result"] = result
        }
        return parameters
    }

}

private extension FrequentHouseworkAnalyticsAction {

    var action: String {
        switch self {
        case .create:
            "create"

        case .edit:
            "edit"

        case .delete:
            "delete"

        case .importFromTemplate:
            "import"

        case .limitReached:
            "limit_reached"

        case .createCategory:
            "create_category"

        case .editCategory:
            "edit_category"

        case .deleteCategory:
            "delete_category"
        }
    }

    /// どの画面での行動か。起点が複数ある行動のみ持つ
    var step: String? {
        switch self {
        case let .create(step, _),
             let .limitReached(step):
            step.rawValue

        case .edit, .delete, .importFromTemplate, .createCategory, .editCategory, .deleteCategory:
            nil
        }
    }

    /// 行動の結果。GA上でそのまま読める値にするため、真偽値ではなく意味のある文字列にする
    var result: String? {
        switch self {
        case let .create(_, isSuccess),
             let .edit(isSuccess),
             let .delete(isSuccess),
             let .importFromTemplate(isSuccess),
             let .createCategory(isSuccess),
             let .editCategory(isSuccess),
             let .deleteCategory(isSuccess):
            isSuccess ? "success" : "failure"

        case .limitReached:
            nil
        }
    }

}
