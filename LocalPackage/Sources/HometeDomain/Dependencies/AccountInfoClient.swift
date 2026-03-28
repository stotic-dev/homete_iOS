//
//  AccountInfoClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public struct AccountInfoClient: Sendable {

    public let insertOrUpdate: @Sendable (Account) async throws -> Void
    public let fetch: @Sendable (String) async throws -> Account?

    public init(
        insertOrUpdate: @Sendable @escaping (Account) async throws -> Void = { _ in },
        fetch: @Sendable @escaping (String) async throws -> Account? = { _ in nil }
    ) {
        self.insertOrUpdate = insertOrUpdate
        self.fetch = fetch
    }
}

public extension AccountInfoClient {

    static let previewValue: AccountInfoClient = .init()
}
