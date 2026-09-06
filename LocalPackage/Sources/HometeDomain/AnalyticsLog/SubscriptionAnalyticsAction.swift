//
//  SubscriptionAnalyticsAction.swift
//  LocalPackage
//

/// 契約中プランの管理に関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `subscription`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum SubscriptionAnalyticsAction: Equatable, Sendable {

    /// 過去の購入を復元した
    case restore(isSuccess: Bool)
    /// OSのサブスクリプション管理画面を起動した
    case manageOpened(isSuccess: Bool)

}

extension SubscriptionAnalyticsAction {

    /// `subscription`イベントに載せるパラメータ
    var parameters: [String: String] {
        ["action": action, "result": result]
    }

}

private extension SubscriptionAnalyticsAction {

    var action: String {
        switch self {
        case .restore:
            "restore"

        case .manageOpened:
            "manage_opened"
        }
    }

    /// 行動の結果。GA上でそのまま読める値にするため、真偽値ではなく意味のある文字列にする
    var result: String {
        switch self {
        case let .restore(isSuccess),
             let .manageOpened(isSuccess):
            isSuccess ? "success" : "failure"
        }
    }

}
