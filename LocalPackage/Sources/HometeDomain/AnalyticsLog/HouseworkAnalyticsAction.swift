//
//  HouseworkAnalyticsAction.swift
//  LocalPackage
//

/// 家事に関する行動の起点画面
public enum HouseworkAnalyticsStep: String, Equatable, Sendable {

    /// ダッシュボード（ホーム画面の今日の家事サマリー、未完了の家事一覧を含む）
    case dashboard
    /// 家事ボード
    case board
    /// 家事の詳細
    case detail
    /// ありがとうを伝える画面
    case thanks

}

/// 家事を完了にしたときの担当者の組み合わせ
public enum HouseworkAnalyticsExecutorType: String, Equatable, Sendable {

    /// 操作した本人だけが担当者
    case ownOnly = "self"
    /// 操作した本人以外だけが担当者（代わりに記録した）
    case others
    /// 操作した本人を含む複数人が担当者（手分けした）
    case shared

    public init(executors: [HouseworkExecutor], reporterId: String) {
        let includesReporter = executors.contains { $0.userId == reporterId }
        let includesOthers = executors.contains { $0.userId != reporterId }
        switch (includesReporter, includesOthers) {
        case (true, true):
            self = .shared

        case (false, true):
            self = .others

        case (_, false):
            self = .ownOnly
        }
    }

}

/// 家事に関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `housework`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum HouseworkAnalyticsAction: Equatable, Sendable {

    /// 家事を登録した
    case register(step: HouseworkAnalyticsStep, isSuccess: Bool)
    /// 家事を完了にした
    case complete(step: HouseworkAnalyticsStep, executorType: HouseworkAnalyticsExecutorType, isSuccess: Bool)
    /// 完了した家事にありがとうを伝えた
    case sendThanks(step: HouseworkAnalyticsStep, isSuccess: Bool)
    /// 家事を未完了に戻した
    case returnIncomplete(step: HouseworkAnalyticsStep, isSuccess: Bool)
    /// 家事を削除した
    case delete(step: HouseworkAnalyticsStep, isSuccess: Bool)

}

extension HouseworkAnalyticsAction {

    /// `housework`イベントに載せるパラメータ
    /// - Note: `action`は全ケースで送り、`step`・`executor_type`・`result`はそれぞれ意味を持つケースのみ追加する
    var parameters: [String: String] {
        var parameters = ["action": action]
        if let step {
            parameters["step"] = step
        }
        if let executorType {
            parameters["executor_type"] = executorType
        }
        if let result {
            parameters["result"] = result
        }
        return parameters
    }

}

private extension HouseworkAnalyticsAction {

    /// どの画面での行動かを示す
    var step: String? {
        switch self {
        case let .register(step, _),
             let .complete(step, _, _),
             let .sendThanks(step, _),
             let .returnIncomplete(step, _),
             let .delete(step, _):
            step.rawValue
        }
    }

    /// 完了にしたときの担当者の組み合わせ
    var executorType: String? {
        switch self {
        case let .complete(_, executorType, _):
            executorType.rawValue

        case .register,
             .sendThanks,
             .returnIncomplete,
             .delete:
            nil
        }
    }

    /// どの行動かを示す
    var action: String {
        switch self {
        case .register:
            "register"

        case .complete:
            "complete"

        case .sendThanks:
            "send_thanks"

        case .returnIncomplete:
            "return_incomplete"

        case .delete:
            "delete"
        }
    }

    /// 行動の結果。GA上でそのまま読める値にするため、真偽値ではなく意味のある文字列にする
    var result: String? {
        switch self {
        case let .register(_, isSuccess),
             let .complete(_, _, isSuccess),
             let .sendThanks(_, isSuccess),
             let .returnIncomplete(_, isSuccess),
             let .delete(_, isSuccess):
            isSuccess ? "success" : "failure"
        }
    }

}
