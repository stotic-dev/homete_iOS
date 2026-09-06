//
//  CohabitantRegistrationAnalyticsAction.swift
//  LocalPackage
//

/// 同居人グループを作成する方法
public enum CohabitantRegistrationMethod: String, Equatable, Sendable {

    /// 近接（P2P）通信での登録
    case p2p
    /// 招待リンクからの参加
    case link

}

/// 同居人グループ作成フローの進捗
/// - Note: 招待リンクの発行・参加は`CohabitantInvitationAnalyticsAction`が担当するため、
///         こちらはP2P・リンクの両方法を横断したグループ作成フローそのものの進捗を担当する。
///         GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `cohabitant_registration`イベント1つにまとめ、この型が生成するパラメータで区別する
public enum CohabitantRegistrationAnalyticsAction: Equatable, Sendable {

    /// グループ作成フローを開始した
    case started(method: CohabitantRegistrationMethod)
    /// P2Pで相手を発見した
    case peerFound
    /// グループ作成が完了した
    case completed(method: CohabitantRegistrationMethod, isSuccess: Bool)

}

extension CohabitantRegistrationAnalyticsAction {

    /// `cohabitant_registration`イベントに載せるパラメータ
    /// - Note: `method`と`action`は全ケースで送り、結果を伴う行動のみ`result`を追加する
    var parameters: [String: String] {
        var parameters = ["method": method, "action": action]
        if let result {
            parameters["result"] = result
        }
        return parameters
    }

}

private extension CohabitantRegistrationAnalyticsAction {

    var method: String {
        switch self {
        case let .started(method):
            method.rawValue

        // P2Pでの発見のみ発生する行動のため固定値にする
        case .peerFound:
            CohabitantRegistrationMethod.p2p.rawValue

        case let .completed(method, _):
            method.rawValue
        }
    }

    var action: String {
        switch self {
        case .started:
            "started"

        case .peerFound:
            "peer_found"

        case .completed:
            "completed"
        }
    }

    var result: String? {
        switch self {
        case let .completed(_, isSuccess):
            isSuccess ? "success" : "failure"

        case .started, .peerFound:
            nil
        }
    }

}
