//
//  AccountLinkAnalyticsAction.swift
//  LocalPackage
//

/// 匿名のアカウントをAppleアカウントと連携する行動
/// - Note: 起点ごと・結果ごとにイベント名を増やさず、`account_link`イベント1つにまとめ、この型が生成するパラメータで区別する
public struct AccountLinkAnalyticsAction: Equatable, Sendable {

    public let entry: AccountLinkEntry
    public let result: AccountLinkAnalyticsResult

    public init(entry: AccountLinkEntry, result: AccountLinkAnalyticsResult) {
        self.entry = entry
        self.result = result
    }

}

/// Apple連携を求めた場所
public enum AccountLinkEntry: String, Equatable, Sendable {

    /// オンボーディングのステップ
    case onboarding
    /// 匿名のままグループに参加していて、全画面で連携を求めた
    case required
    /// 未参加ホームのやることリスト
    case todo
    /// 設定画面
    case setting
    /// Paywallを開く前
    case paywall

}

/// Apple連携の結果
public enum AccountLinkAnalyticsResult: String, Equatable, Sendable {

    /// 連携した
    case success
    /// 連携せずに閉じた、または既存のアカウントへの切り替えをやめた
    case cancel
    /// すでに使われていたAppleアカウントのアカウントへ切り替えた
    case conflictSwitched = "conflict_switched"
    /// 連携に失敗した
    case failure

}

extension AccountLinkAnalyticsAction {

    /// `account_link`イベントに載せるパラメータ
    var parameters: [String: String] {
        ["entry": entry.rawValue, "result": result.rawValue]
    }

}
