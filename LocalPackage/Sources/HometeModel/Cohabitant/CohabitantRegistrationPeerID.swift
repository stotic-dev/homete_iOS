//
//  CohabitantRegistrationPeerID.swift
//  LocalPackage
//

/// P2P登録で通信相手を識別するID
/// - Note: `MCPeerID`の`displayName`（`ユーザー名_UUID`）をそのまま値に持つ。
///         `MCPeerID`は`Sendable`でないため、状態遷移をドメイン層で扱えるよう値型に写している。
///         リーダー選出は`displayName`の辞書順で行うため`Comparable`にしている
public struct CohabitantRegistrationPeerID: Hashable, Comparable, Sendable {

    public let displayName: String

    /// 一覧に表示するユーザー名（`displayName`からUUIDを除いた部分）
    public var userName: String {
        displayName.split(separator: "_", maxSplits: 1).first.map(String.init) ?? displayName
    }

    public init(displayName: String) {
        self.displayName = displayName
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.displayName < rhs.displayName
    }

}
