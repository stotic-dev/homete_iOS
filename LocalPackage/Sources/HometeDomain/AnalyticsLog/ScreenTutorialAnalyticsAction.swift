//
//  ScreenTutorialAnalyticsAction.swift
//  LocalPackage
//

/// 画面を初めて開いたときに出すチュートリアルに関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、画面や行動ごとにイベント名を増やさず
///         `screen_tutorial`イベント1つにまとめ、この型が生成するパラメータで区別する。
///         どの画面のどのステップで閉じられたかを見て、案内の長さや順番を見直せるようにする
public enum ScreenTutorialAnalyticsAction: Equatable, Sendable {

    /// 最後のステップまで見た
    case completed(screen: ScreenTutorial)
    /// 途中で閉じた
    /// - Parameter step: 閉じたときに表示していたステップの`rawValue`
    case skipped(screen: ScreenTutorial, step: String)

}

extension ScreenTutorialAnalyticsAction {

    /// `screen_tutorial`イベントに載せるパラメータ
    /// - Note: `screen`と`action`は全ケースで送り、途中で閉じた場合のみ`step`を追加する
    var parameters: [String: String] {
        switch self {
        case let .completed(screen):
            ["screen": screen.rawValue, "action": "completed"]

        case let .skipped(screen, step):
            ["screen": screen.rawValue, "action": "skipped", "step": step]
        }
    }

}
