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
    /// 複数の家事に、同じありがとうをまとめて記録する（送った人の分だけを書き換え、ほかの人の記録には触れない）
    /// - Note: `WriteBatch`で一括書き込みし、全件成功か全件失敗かのどちらかにする
    public let upsertThanksBatch: @Sendable (
        _ houseworkIds: [String],
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
    /// 家事のドキュメントをまとめて新しく作る（画像の参照も書く）
    /// - Note: `WriteBatch`で一括書き込みし、全件成功か全件失敗かのどちらかにする。
    ///         既存の家事の書き換え（`insertOrUpdateItem(s)`）は画像の参照に触れないため、画像を添えて作るときはこちらを使う
    public let createItems: @Sendable (_ items: [HouseworkItem], _ cohabitantId: String) async throws -> Void
    /// 家事に画像の参照を足す（同居人が同時に足した画像を消さないよう、配列に追記する）
    public let addImages: @Sendable (
        _ houseworkId: String,
        _ images: [HouseworkImage],
        _ cohabitantId: String
    ) async throws -> Void
    /// まだドキュメントの無い家事に画像を添える。同居人が先にドキュメントを作っていたら、画像の参照を追記するだけにする
    /// - Note: 有無の確認と書き込みを1つのトランザクションで行う。テンプレートから出している家事を、画像を上げている間に
    ///         同居人が完了にした・画像を添えたときに、手元の古い記録でドキュメントごと上書きしないため
    public let createItemOrAddImages: @Sendable (
        _ item: HouseworkItem,
        _ images: [HouseworkImage],
        _ cohabitantId: String
    ) async throws -> Void
    /// 家事から画像の参照を1つ取り除く（ほかの画像には触れない）
    public let removeImage: @Sendable (
        _ houseworkId: String,
        _ image: HouseworkImage,
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
        upsertThanksBatchHandler: @escaping @Sendable (
            _ houseworkIds: [String],
            _ senderId: String,
            _ thanks: HouseworkThanks,
            _ cohabitantId: String
        ) async throws -> Void = { _, _, _, _ in },
        updateMemoHandler: @escaping @Sendable (
            _ houseworkId: String,
            _ memo: HouseworkMemo,
            _ cohabitantId: String
        ) async throws -> Void = { _, _, _ in },
        createItemsHandler: (@Sendable (
            _ items: [HouseworkItem],
            _ cohabitantId: String
        ) async throws -> Void)? = nil,
        addImagesHandler: (@Sendable (
            _ houseworkId: String,
            _ images: [HouseworkImage],
            _ cohabitantId: String
        ) async throws -> Void)? = nil,
        createItemOrAddImagesHandler: (@Sendable (
            _ item: HouseworkItem,
            _ images: [HouseworkImage],
            _ cohabitantId: String
        ) async throws -> Void)? = nil,
        removeImageHandler: (@Sendable (
            _ houseworkId: String,
            _ image: HouseworkImage,
            _ cohabitantId: String
        ) async throws -> Void)? = nil,
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
        ) async throws -> [HouseworkItem] = { _, _, _ in [] }
    ) {
        insertOrUpdateItem = insertOrUpdateItemHandler
        insertOrUpdateItems = insertOrUpdateItemsHandler
        removeItem = removeItemHandler
        upsertThanks = upsertThanksHandler
        upsertThanksBatch = upsertThanksBatchHandler
        updateMemo = updateMemoHandler
        // デフォルト引数にクロージャを書くと、Xcode 26系（Swift 6.2〜6.3）のビルドで並列に呼ばれたときに
        // asyncフレームが壊れてクラッシュするため、後から足した処理はnilを既定値にして本体で代入する
        createItems = createItemsHandler ?? { _, _ in }
        addImages = addImagesHandler ?? { _, _, _ in }
        createItemOrAddImages = createItemOrAddImagesHandler ?? { _, _, _ in }
        removeImage = removeImageHandler ?? { _, _, _ in }
        snapshotListener = snapshotListenerHandler
        removeListener = removeListenerHandler
        fetchItems = fetchItemsHandler
    }

    static let previewValue = HouseworkClient()

}
