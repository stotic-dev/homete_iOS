//
//  RegistrationTutorialAnalyticsAction.swift
//  LocalPackage
//

/// グループ登録の直後に出すチュートリアルに関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `registration_tutorial`イベント1つにまとめ、この型が生成するパラメータで区別する。
///         どのステップで閉じられたかを見て、案内の長さや順番を見直せるようにする
public enum RegistrationTutorialAnalyticsAction: Equatable, Sendable {

    /// 最後のステップまで見た
    case completed
    /// 途中で閉じた
    /// - Parameter step: 閉じたときに表示していたステップ
    case skipped(step: RegistrationTutorialStep)

}

extension RegistrationTutorialAnalyticsAction {

    /// `registration_tutorial`イベントに載せるパラメータ
    /// - Note: `action`は全ケースで送り、途中で閉じた場合のみ`step`を追加する
    var parameters: [String: String] {
        switch self {
        case .completed:
            ["action": "completed"]

        case let .skipped(step):
            ["action": "skipped", "step": step.rawValue]
        }
    }

}
