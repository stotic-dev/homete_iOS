//
//  CohabitantClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/18.
//

public struct CohabitantClient: Sendable {

    public let register: @Sendable (CohabitantData) async throws -> Void
    public let addSnapshotListener: @Sendable (
        _ listenerId: String,
        _ cohabitantId: String
    ) async -> AsyncStream<[CohabitantData]>
    public let removeSnapshotListener: @Sendable (_ listenerId: String) async -> Void

    public init(
        register: @Sendable @escaping (CohabitantData) async throws -> Void = { _ in },
        addSnapshotListener: @Sendable @escaping (
            _: String,
            _: String
        ) async -> AsyncStream<[CohabitantData]> = { _, _ in .init { nil } },
        removeSnapshotListener: @Sendable @escaping (_ listenerId: String) async -> Void = { _ in }
    ) {

        self.register = register
        self.addSnapshotListener = addSnapshotListener
        self.removeSnapshotListener = removeSnapshotListener
    }
}

public extension CohabitantClient {

    static let previewValue: CohabitantClient = .init()
}
