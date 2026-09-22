//
//  CohabitantInvitationClient.swift
//  LocalPackage
//

public struct CohabitantInvitationClient: Sendable {

    /// 招待トークンを発行する
    /// - Note: 発行時にはグループを作らない。グループ未所属の場合は、参加者が現れた時点でサーバー側が
    ///         発行者と参加者のグループを作り、発行者の`Account.cohabitantId`も更新する
    public let issue: @Sendable () async throws -> CohabitantInvitation
    /// 参加前に表示する招待の概要（招待者名・有効期限）を取得する
    /// - Note: 無効・期限切れは`join`と同じエラーで投げられるため、参加ボタンを押す前に失敗が分かる
    public let fetch: @Sendable (_ token: String) async throws -> CohabitantInvitationSummary
    /// 招待トークンを使ってグループに参加する
    /// - Returns: 参加したグループのIDと、新しくメンバーになったかどうか
    public let join: @Sendable (_ token: String) async throws -> CohabitantJoinResult

    public init(
        issue: @Sendable @escaping () async throws -> CohabitantInvitation = { .preview },
        fetch: @Sendable @escaping (_ token: String) async throws -> CohabitantInvitationSummary = { _ in
            .preview
        },
        join: @Sendable @escaping (_ token: String) async throws -> CohabitantJoinResult = { _ in
            .init(cohabitantId: "", isNewMember: true)
        }
    ) {
        self.issue = issue
        self.fetch = fetch
        self.join = join
    }

}

public extension CohabitantInvitationClient {

    static let previewValue: CohabitantInvitationClient = .init()

}
