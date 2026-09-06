//
//  OnboardingAnalyticsAction.swift
//  LocalPackage
//

/// オンボーディング中に発生した行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `onboarding`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum OnboardingAnalyticsAction: Equatable, Sendable {

    /// プレミアムプランの特典説明画面を表示した
    case premiumIntroductionShown
    /// 特典説明画面からPaywallを開いた
    case paywallShown
    /// 特典説明画面から開いたPaywallを閉じた
    /// - Parameter isPremium: 閉じた時点でプレミアムプランが有効かどうか（購入せずスキップした場合はfalse）
    case paywallClosed(isPremium: Bool)
    /// 特典説明画面からPaywallを開かずに次へ進んだ
    case premiumIntroductionSkipped

}

extension OnboardingAnalyticsAction {

    /// `onboarding`イベントに載せるパラメータ
    /// - Note: `step`と`action`は全ケースで送り、結果を伴う行動のみ`result`を追加する
    var parameters: [String: String] {
        var parameters = ["step": step, "action": action]
        if let result {
            parameters["result"] = result
        }
        return parameters
    }

}

private extension OnboardingAnalyticsAction {

    /// どの画面での行動かを示す
    /// - Note: 現状は特典説明画面の行動のみのため固定値。通知権限の案内は`NotificationPermissionAnalyticsAction`が担当する
    var step: String {
        "premium_introduction"
    }

    /// 画面内で何が起きたかを示す
    var action: String {
        switch self {
        case .premiumIntroductionShown:
            "shown"

        case .paywallShown:
            "paywall_shown"

        case .paywallClosed:
            "paywall_closed"

        case .premiumIntroductionSkipped:
            "skipped"
        }
    }

    /// 行動の結果。GA上でそのまま読める値にするため、真偽値ではなく意味のある文字列にする
    var result: String? {
        switch self {
        case let .paywallClosed(isPremium):
            isPremium ? "purchased" : "not_purchased"

        case .premiumIntroductionShown, .paywallShown, .premiumIntroductionSkipped:
            nil
        }
    }

}
