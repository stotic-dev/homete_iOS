//
//  CohabitantInvitationAnalyticsAction.swift
//  LocalPackage
//

/// 招待リンクに関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `cohabitant_invitation`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum CohabitantInvitationAnalyticsAction: Equatable, Sendable {

    /// 招待リンクを発行した
    /// - Parameters:
    ///   - screen: 発行を開始した画面
    ///   - isSuccess: 発行に成功したかどうか
    case issued(screen: CohabitantInvitationIssueScreen, isSuccess: Bool)
    /// 招待リンクからアプリが起動した
    case linkOpened
    /// 招待リンクからグループに参加した
    case joinSucceeded
    /// 招待リンクからのグループ参加に失敗した
    case joinFailed(CohabitantJoinFailure)

}

extension CohabitantInvitationAnalyticsAction {

    /// `cohabitant_invitation`イベントに載せるパラメータ
    /// - Note: `action`は全ケースで送り、画面を起点とする行動のみ`step`、結果を伴う行動のみ`result`を追加する
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

private extension CohabitantInvitationAnalyticsAction {

    /// どの画面での行動かを示す。画面を起点としない行動ではnil
    var step: String? {
        switch self {
        case let .issued(screen, _):
            screen.rawValue

        // リンク経由の起動・参加は画面から始まる行動ではないため付けない
        case .linkOpened, .joinSucceeded, .joinFailed:
            nil
        }
    }

    /// どの行動かを示す
    var action: String {
        switch self {
        case .issued:
            "issue"

        case .linkOpened:
            "open"

        case .joinSucceeded, .joinFailed:
            "join"
        }
    }

    /// 行動の結果。GA上でそのまま読める値にするため、真偽値ではなく意味のある文字列にする
    var result: String? {
        switch self {
        case let .issued(_, isSuccess):
            isSuccess ? "success" : "failure"

        case .linkOpened:
            nil

        case .joinSucceeded:
            "success"

        case let .joinFailed(failure):
            switch failure {
            case .invalidLink: "invalid_link"
            case .expired: "expired"
            case .alreadyJoined: "already_joined"
            case .unknown: "failure"
            }
        }
    }

}

/// 招待リンクの発行を開始した画面
/// - Note: GA4のカスタムディメンションにも登録数の上限があるため、専用のキーを作らず
///         `onboarding`と同じ`step`パラメータに載せる
public enum CohabitantInvitationIssueScreen: String, Equatable, Sendable {

    /// 同居人登録画面の「リンクで招待」
    case cohabitantRegistration = "cohabitant_registration"
    /// 設定画面の「メンバー招待」
    case setting

}
