//
//  HouseworkClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import Foundation

public struct HouseworkClient: Sendable {

    public let insertOrUpdateItem: @Sendable (_ item: HouseworkItem, _ cohabitantId: String) async throws -> Void
    public let removeItem: @Sendable (_ item: HouseworkItem, _ cohabitantId: String) async throws -> Void
    public let snapshotListener: @Sendable (
        _ id: String,
        _ cohabitantId: String,
        _ anchorDate: Date,
        _ offset: Int
    ) async -> AsyncStream<[HouseworkItem]>
    public let removeListener: @Sendable (_ id: String) async -> Void
}

public extension HouseworkClient {

    init(
        insertOrUpdateItemHandler: @escaping @Sendable (
            _ item: HouseworkItem,
            _ cohabitantId: String
        ) async throws -> Void = { _, _ in },
        removeItemHandler: @escaping @Sendable (
            _ item: HouseworkItem,
            _ cohabitantId: String
        ) async throws -> Void = { _, _ in },
        snapshotListenerHandler: @escaping @Sendable (
            _ id: String,
            _ cohabitantId: String,
            _ anchorDate: Date,
            _ offset: Int
        ) async -> AsyncStream<[HouseworkItem]> = { _, _, _, _ in .makeStream().stream },
        removeListenerHandler: @escaping @Sendable (_ id: String) async -> Void = { _ in }
    ) {

        insertOrUpdateItem = insertOrUpdateItemHandler
        removeItem = removeItemHandler
        snapshotListener = snapshotListenerHandler
        removeListener = removeListenerHandler
    }

    static let previewValue = HouseworkClient()
}
