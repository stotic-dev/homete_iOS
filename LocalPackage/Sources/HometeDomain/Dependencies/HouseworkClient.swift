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
    public let fetchItems: @Sendable (
        _ cohabitantId: String,
        _ from: Date,
        _ to: Date
    ) async throws -> [HouseworkItem]
    /// 同居人グループの家事データの保持期限を、現在のプランに合わせて再計算する
    public let syncRetention: @Sendable (_ cohabitantId: String) async throws -> Void

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
        removeListenerHandler: @escaping @Sendable (_ id: String) async -> Void = { _ in },
        fetchItemsHandler: @escaping @Sendable (
            _ cohabitantId: String,
            _ from: Date,
            _ to: Date
        ) async throws -> [HouseworkItem] = { _, _, _ in [] },
        syncRetentionHandler: @escaping @Sendable (_ cohabitantId: String) async throws -> Void = { _ in }
    ) {
        insertOrUpdateItem = insertOrUpdateItemHandler
        removeItem = removeItemHandler
        snapshotListener = snapshotListenerHandler
        removeListener = removeListenerHandler
        fetchItems = fetchItemsHandler
        syncRetention = syncRetentionHandler
    }

    static let previewValue = HouseworkClient()

}
