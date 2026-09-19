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
    /// 家事の承認
    case approval

}

/// 家事に関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `housework`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum HouseworkAnalyticsAction: Equatable, Sendable {

    /// 家事を登録した
    case register(step: HouseworkAnalyticsStep, isSuccess: Bool)
    /// 家事の確認を依頼した
    case requestReview(step: HouseworkAnalyticsStep, isSuccess: Bool)
    /// 家事を承認した
    case approve(isSuccess: Bool)
    /// 家事を差し戻した
    case reject(isSuccess: Bool)
    /// 家事を未完了に戻した
    case returnIncomplete(step: HouseworkAnalyticsStep, isSuccess: Bool)
    /// 家事を削除した
    case delete(step: HouseworkAnalyticsStep, isSuccess: Bool)

}

extension HouseworkAnalyticsAction {

    /// `housework`イベントに載せるパラメータ
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

private extension HouseworkAnalyticsAction {

    /// どの画面での行動かを示す
    var step: String? {
        switch self {
        case let .register(step, _),
             let .requestReview(step, _),
             let .returnIncomplete(step, _),
             let .delete(step, _):
            step.rawValue

        // 承認・差し戻しは常に承認画面からの行動のため固定値にする
        case .approve, .reject:
            HouseworkAnalyticsStep.approval.rawValue
        }
    }

    /// どの行動かを示す
    var action: String {
        switch self {
        case .register:
            "register"

        case .requestReview:
            "request_review"

        case .approve:
            "approve"

        case .reject:
            "reject"

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
             let .requestReview(_, isSuccess),
             let .returnIncomplete(_, isSuccess),
             let .delete(_, isSuccess),
             let .approve(isSuccess),
             let .reject(isSuccess):
            isSuccess ? "success" : "failure"
        }
    }

}
