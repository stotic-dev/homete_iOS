//
//  CohabitantInvitationClient.swift
//  LocalPackage
//

public struct CohabitantInvitationClient: Sendable {

    /// 招待トークンを発行する
    /// - Note: グループ未所属の場合は、本人のみが所属するグループが新規作成される
    public let issue: @Sendable () async throws -> CohabitantInvitation
    /// 招待トークンを使ってグループに参加する
    /// - Returns: 参加したグループのID
    public let join: @Sendable (_ token: String) async throws -> String

    public init(
        issue: @Sendable @escaping () async throws -> CohabitantInvitation = { .preview },
        join: @Sendable @escaping (_ token: String) async throws -> String = { _ in "" }
    ) {
        self.issue = issue
        self.join = join
    }

}

public extension CohabitantInvitationClient {

    static let previewValue: CohabitantInvitationClient = .init()

}
