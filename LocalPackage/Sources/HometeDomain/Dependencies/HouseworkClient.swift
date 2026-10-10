//
//  HouseworkClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import Foundation

public struct HouseworkClient: Sendable {

    public let insertOrUpdateItem: @Sendable (_ item: HouseworkItem, _ cohabitantId: String) async throws -> Void
    /// 家事をまとめて作成または上書きする
    /// - Note: `WriteBatch`で一括書き込みし、全件成功か全件失敗かのどちらかにする
    public let insertOrUpdateItems: @Sendable (_ items: [HouseworkItem], _ cohabitantId: String) async throws -> Void
    public let removeItem: @Sendable (_ item: HouseworkItem, _ cohabitantId: String) async throws -> Void
    /// 家事に送ったありがとうを記録する（送った人の分だけを書き換え、ほかの人の記録には触れない）
    public let upsertThanks: @Sendable (
        _ houseworkId: String,
        _ senderId: String,
        _ thanks: HouseworkThanks,
        _ cohabitantId: String
    ) async throws -> Void
    /// 家事のメモだけを書き換える（完了など、同時に起きたほかの変更を巻き戻さないため）
    public let updateMemo: @Sendable (
        _ houseworkId: String,
        _ memo: HouseworkMemo,
        _ cohabitantId: String
    ) async throws -> Void
    public let snapshotListener: @Sendable (
        _ id: String,
        _ cohabitantId: String,
        _ anchorDate: Date,
        _ offset: Int
    ) async -> AsyncThrowingStream<[HouseworkItem], Error>
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
        insertOrUpdateItemsHandler: @escaping @Sendable (
            _ items: [HouseworkItem],
            _ cohabitantId: String
        ) async throws -> Void = { _, _ in },
        removeItemHandler: @escaping @Sendable (
            _ item: HouseworkItem,
            _ cohabitantId: String
        ) async throws -> Void = { _, _ in },
        upsertThanksHandler: @escaping @Sendable (
            _ houseworkId: String,
            _ senderId: String,
            _ thanks: HouseworkThanks,
            _ cohabitantId: String
        ) async throws -> Void = { _, _, _, _ in },
        updateMemoHandler: @escaping @Sendable (
            _ houseworkId: String,
            _ memo: HouseworkMemo,
            _ cohabitantId: String
        ) async throws -> Void = { _, _, _ in },
        snapshotListenerHandler: @escaping @Sendable (
            _ id: String,
            _ cohabitantId: String,
            _ anchorDate: Date,
            _ offset: Int
        ) async -> AsyncThrowingStream<[HouseworkItem], Error> = { _, _, _, _ in .makeStream().stream },
        removeListenerHandler: @escaping @Sendable (_ id: String) async -> Void = { _ in },
        fetchItemsHandler: @escaping @Sendable (
            _ cohabitantId: String,
            _ from: Date,
            _ to: Date
        ) async throws -> [HouseworkItem] = { _, _, _ in [] },
        syncRetentionHandler: @escaping @Sendable (_ cohabitantId: String) async throws -> Void = { _ in }
    ) {
        insertOrUpdateItem = insertOrUpdateItemHandler
        insertOrUpdateItems = insertOrUpdateItemsHandler
        removeItem = removeItemHandler
        upsertThanks = upsertThanksHandler
        updateMemo = updateMemoHandler
        snapshotListener = snapshotListenerHandler
        removeListener = removeListenerHandler
        fetchItems = fetchItemsHandler
        syncRetention = syncRetentionHandler
    }

    static let previewValue = HouseworkClient()

}
