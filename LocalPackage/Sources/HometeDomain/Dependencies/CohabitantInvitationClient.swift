//
//  CohabitantInvitationClient.swift
//  LocalPackage
//

public struct CohabitantInvitationClient: Sendable {

    /// 招待トークンを発行する
    /// - Note: 発行時にはグループを作らない。グループ未所属の場合は、参加者が現れた時点でサーバー側が
    ///         発行者と参加者のグループを作り、発行者の`Account.cohabitantId`も更新する
    public let issue: @Sendable () async throws -> CohabitantInvitation
    /// 招待トークンを使ってグループに参加する
    /// - Returns: 参加したグループのIDと、新しくメンバーになったかどうか
    public let join: @Sendable (_ token: String) async throws -> CohabitantJoinResult

    public init(
        issue: @Sendable @escaping () async throws -> CohabitantInvitation = { .preview },
        join: @Sendable @escaping (_ token: String) async throws -> CohabitantJoinResult = { _ in
            .init(cohabitantId: "", isNewMember: true)
        }
    ) {
        self.issue = issue
        self.join = join
    }

}

public extension CohabitantInvitationClient {

    static let previewValue: CohabitantInvitationClient = .init()

}
