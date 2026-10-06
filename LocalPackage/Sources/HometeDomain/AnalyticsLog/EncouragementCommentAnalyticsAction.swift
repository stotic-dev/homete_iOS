//
//  EncouragementCommentAnalyticsAction.swift
//  LocalPackage
//

/// ねぎらいのコメントを表示した場所
public enum EncouragementCommentAnalyticsStep: String, Equatable, Sendable {

    /// ダッシュボードのコメントカード
    case dashboard

}

/// 表示した・タップしたコメントの種類
public enum EncouragementCommentAnalyticsKind: String, Equatable, Sendable {

    /// 自分の実績をねぎらうコメント
    case selfPraise = "self_praise"
    /// 自分の実績がまだない日の、中立・励ましのコメント
    case neutral
    /// 同居人への感謝の促し
    case thanksPrompt = "thanks_prompt"

}

/// ねぎらいのコメントに関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `encouragement_comment`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum EncouragementCommentAnalyticsAction: Equatable, Sendable {

    /// コメントを表示した
    /// - Note: ねぎらいと感謝の促しを両方出したときは、それぞれ1イベント送る
    case shown(kind: EncouragementCommentAnalyticsKind, step: EncouragementCommentAnalyticsStep)
    /// 感謝の促しの「ありがとうを伝える」をタップした
    case tapped(kind: EncouragementCommentAnalyticsKind, step: EncouragementCommentAnalyticsStep)

}

extension EncouragementCommentAnalyticsAction {

    /// `encouragement_comment`イベントに載せるパラメータ
    var parameters: [String: String] {
        switch self {
        case let .shown(kind, step):
            ["action": "shown", "kind": kind.rawValue, "step": step.rawValue]

        case let .tapped(kind, step):
            ["action": "tapped", "kind": kind.rawValue, "step": step.rawValue]
        }
    }

}
