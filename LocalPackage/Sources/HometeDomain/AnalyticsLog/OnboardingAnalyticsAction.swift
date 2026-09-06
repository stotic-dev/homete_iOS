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
    /// 特典説明画面からPaywallを開かずに次へ進んだ
    case premiumIntroductionSkipped

}

extension OnboardingAnalyticsAction {

    /// `onboarding`イベントに載せるパラメータ
    var parameters: [String: String] {
        ["step": step, "action": action]
    }

}

private extension OnboardingAnalyticsAction {

    /// どの画面での行動かを示す
    /// - Note: 現状は特典説明画面の行動のみのため固定値。通知権限の案内は`NotificationPermissionAnalyticsAction`が、
    ///         Paywallの表示・クローズは`PaywallAnalyticsAction`が担当する
    var step: String {
        "premium_introduction"
    }

    /// 画面内で何が起きたかを示す
    var action: String {
        switch self {
        case .premiumIntroductionShown:
            "shown"

        case .premiumIntroductionSkipped:
            "skipped"
        }
    }

}
