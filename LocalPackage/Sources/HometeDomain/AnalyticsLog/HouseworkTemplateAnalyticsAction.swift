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
    /// - Note: テンプレート画面では保存時にドラフトとの差分から検出するため、追加された家事1件ごとに1イベント送る。
    ///         家事登録画面では繰り返しを設定して登録したときに1イベント送る
    case create(isSuccess: Bool, step: HouseworkTemplateAnalyticsStep, recurrence: HouseworkRecurrence)
    /// テンプレートの家事を編集した
    /// - Note: 保存時にドラフトとの差分から検出するため、編集された家事1件ごとに1イベント送る
    case edit(isSuccess: Bool, recurrence: HouseworkRecurrence)
    /// テンプレートの家事を削除した
    /// - Note: 保存時にドラフトとの差分から検出するため、削除された家事1件ごとに1イベント送る
    case delete(isSuccess: Bool)

}

/// テンプレートに家事を追加した起点画面
public enum HouseworkTemplateAnalyticsStep: String, Equatable, Sendable {

    /// 家事テンプレート画面
    case template
    /// 家事登録画面（繰り返しを設定して登録）
    case register

}

extension HouseworkTemplateAnalyticsAction {

    /// `housework_template`イベントに載せるパラメータ
    /// - Note: `action`は全ケースで送り、`result`はGA上でそのまま読める値にするため真偽値ではなく意味のある文字列にする。
    ///         `step`は追加時だけ、`recurrence`は追加・編集時だけ送る
    var parameters: [String: String] {
        var parameters = ["action": action, "result": result]
        switch self {
        case let .create(_, step, recurrence):
            parameters["step"] = step.rawValue
            parameters["recurrence"] = recurrence.analyticsValue

        case let .edit(_, recurrence):
            parameters["recurrence"] = recurrence.analyticsValue

        case .apply, .delete:
            break
        }
        return parameters
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
             let .create(isSuccess, _, _),
             let .edit(isSuccess, _),
             let .delete(isSuccess):
            isSuccess ? "success" : "failure"
        }
    }

}

private extension HouseworkRecurrence {

    var analyticsValue: String {
        switch self {
        case .weekly:
            "weekly"

        case .monthly(.dayOfMonth):
            "monthly_day"

        case .monthly(.weekdayOfMonth):
            "monthly_weekday"
        }
    }

}
