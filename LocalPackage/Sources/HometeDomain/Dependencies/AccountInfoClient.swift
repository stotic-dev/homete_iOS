//
//  AccountInfoClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public struct AccountInfoClient: Sendable {

    public let insertOrUpdate: @Sendable (Account) async throws -> Void
    public let fetch: @Sendable (String) async throws -> Account?
    /// 自分のアカウントを購読する
    /// - Note: 招待リンク経由の参加ではサーバー側（Cloud Functions）が発行者の`cohabitantId`を更新するため、
    ///         クライアント起点の書き込みだけでは自分のアカウントの変化を検知できない
    public let addSnapshotListener: @Sendable (
        _ listenerId: String,
        _ accountId: String
    ) async -> AsyncThrowingStream<Account?, Error>
    public let removeSnapshotListener: @Sendable (_ listenerId: String) async -> Void

    public init(
        insertOrUpdate: @Sendable @escaping (Account) async throws -> Void = { _ in },
        fetch: @Sendable @escaping (String) async throws -> Account? = { _ in nil },
        addSnapshotListener: @Sendable @escaping (
            _: String,
            _: String
        ) async -> AsyncThrowingStream<Account?, Error> = { _, _ in .init { $0.finish() } },
        removeSnapshotListener: @Sendable @escaping (_ listenerId: String) async -> Void = { _ in }
    ) {
        self.insertOrUpdate = insertOrUpdate
        self.fetch = fetch
        self.addSnapshotListener = addSnapshotListener
        self.removeSnapshotListener = removeSnapshotListener
    }

}

public extension AccountInfoClient {

    static let previewValue: AccountInfoClient = .init()

}
