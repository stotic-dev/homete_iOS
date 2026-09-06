//
//  PaywallAnalyticsAction.swift
//  LocalPackage
//

/// Paywallへの導線となる起点
public enum PaywallAnalyticsStep: String, Equatable, Sendable {

    /// オンボーディングの特典説明画面
    case onboarding
    /// ダッシュボードの広告バナー下リンク
    case dashboardAd = "dashboard_ad"
    /// 家事分析画面の広告バナー下リンク
    /// - Note: `advertisement`イベントの`step`では`contribution_analytics`と表記しているのと同じ導線。
    ///         `paywall`イベントの`step`名はIssue設計時点の命名をそのまま踏襲しているため、
    ///         「家事ボード」ではなく家事分析画面を指す点に注意
    case boardAd = "board_ad"
    /// 家事ボードの保存期間上限セル（`HouseworkStorageLimitCell`）
    case boardStorageLimit = "board_storage_limit"
    /// 家事テンプレート画面の広告バナー下リンク
    case templateAd = "template_ad"
    /// 家事分析画面の保存期間上限表示（`StoragePeriodLimitView`）
    case contributionStorageLimit = "contribution_storage_limit"
    /// 設定画面のプレミアムプラン項目
    case setting
    /// サブスクリプション管理画面のプラン変更ボタン
    case subscriptionManagement = "subscription_management"

}

/// Paywallの表示・クローズに関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `paywall`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum PaywallAnalyticsAction: Equatable, Sendable {

    /// Paywallを表示した
    case shown(step: PaywallAnalyticsStep)
    /// Paywallを閉じた
    /// - Parameter isPremium: 閉じた時点でプレミアムプランが有効かどうか（購入せずスキップした場合はfalse）
    case closed(step: PaywallAnalyticsStep, isPremium: Bool)

}

extension PaywallAnalyticsAction {

    /// `paywall`イベントに載せるパラメータ
    /// - Note: `step`と`action`は全ケースで送り、結果を伴う`closed`のみ`result`を追加する
    var parameters: [String: String] {
        var parameters = ["step": step, "action": action]
        if let result {
            parameters["result"] = result
        }
        return parameters
    }

}

private extension PaywallAnalyticsAction {

    var step: String {
        switch self {
        case let .shown(step),
             let .closed(step, _):
            step.rawValue
        }
    }

    var action: String {
        switch self {
        case .shown:
            "shown"

        case .closed:
            "closed"
        }
    }

    /// 行動の結果。GA上でそのまま読める値にするため、真偽値ではなく意味のある文字列にする
    var result: String? {
        switch self {
        case .shown:
            nil

        case let .closed(_, isPremium):
            isPremium ? "purchased" : "not_purchased"
        }
    }

}
