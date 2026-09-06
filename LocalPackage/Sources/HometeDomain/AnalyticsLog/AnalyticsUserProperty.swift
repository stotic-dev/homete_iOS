//
//  AnalyticsUserProperty.swift
//  LocalPackage
//

/// ユーザー単位で持続する属性値
/// - Note: `is_premium`のような軸をイベントごとのパラメータで持つと、送信箇所ごとに付け忘れが起きる上、
///         GA4のカスタムディメンション登録数を無駄に消費する。ユーザープロパティとして設定すれば、
///         全イベントを横断してその軸でセグメントできる
public enum AnalyticsUserProperty: Equatable, Sendable {

    /// プレミアム会員かどうか
    case isPremium(Bool)
    /// 同居人グループに参加済みかどうか
    case hasCohabitant(Bool)
    /// 同居人グループのメンバー数（自分を含む）
    case cohabitantMemberCount(Int)

}

public extension AnalyticsUserProperty {

    var name: String {
        switch self {
        case .isPremium:
            "is_premium"

        case .hasCohabitant:
            "has_cohabitant"

        case .cohabitantMemberCount:
            "cohabitant_member_count"
        }
    }

    var value: String {
        switch self {
        case let .isPremium(value):
            "\(value)"

        case let .hasCohabitant(value):
            "\(value)"

        case let .cohabitantMemberCount(value):
            "\(value)"
        }
    }

}
