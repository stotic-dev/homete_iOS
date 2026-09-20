//
//  CohabitantJoinResult.swift
//  LocalPackage
//

/// 招待リンクによるグループ参加の結果
public struct CohabitantJoinResult: Equatable, Sendable {

    /// 参加したグループのID
    public let cohabitantId: String
    /// この参加で新しくメンバーになったかどうか
    /// - Note: すでに同じグループへ参加済みのユーザーがリンクを開いた場合、サーバーは
    ///         エラーにせず成功として扱うため`false`で返る。「すでに参加しています」の案内に使う
    public let isNewMember: Bool

    public init(cohabitantId: String, isNewMember: Bool) {
        self.cohabitantId = cohabitantId
        self.isNewMember = isNewMember
    }

}
