//
//  AppReviewTrigger.swift
//  LocalPackage
//

/// アプリの評価をリクエストするきっかけ
/// - Note: `rawValue`は`app_review`イベントの`trigger`パラメータにそのまま使う
public enum AppReviewTrigger: String, Codable, Sendable {

    /// 無料プランからプレミアムプランに変わった（購入・復元）
    case purchase
    /// 受け取ったありがとうの合計が一定数に達した
    case thanksCount = "thanks_count"
    /// 使い始めてから一定期間たった後にありがとうを受け取った
    case thanksAfterTwoWeeks = "thanks_after_two_weeks"

}
