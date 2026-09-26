//
//  FrequentHouseworkClient.swift
//  LocalPackage
//

public struct FrequentHouseworkClient: Sendable {

    /// いつもの家事のSnapshotListener
    public let addItemsSnapshotListener: @Sendable (
        _ id: String,
        _ cohabitantId: String
    ) async -> AsyncStream<[FrequentHouseworkItem]>

    /// カスタムカテゴリのSnapshotListener
    public let addCategoriesSnapshotListener: @Sendable (
        _ id: String,
        _ cohabitantId: String
    ) async -> AsyncStream<[FrequentHouseworkCustomCategory]>

    /// いつもの家事の作成・更新（追加・編集・並べ替え・取り込みをまとめて書き込む）
    public let upsertItems: @Sendable (
        _ items: [FrequentHouseworkItem],
        _ cohabitantId: String
    ) async throws -> Void

    /// いつもの家事の削除
    public let deleteItem: @Sendable (_ id: String, _ cohabitantId: String) async throws -> Void

    /// カスタムカテゴリの作成・更新（追加・名前変更・並べ替えをまとめて書き込む）
    public let upsertCategories: @Sendable (
        _ categories: [FrequentHouseworkCustomCategory],
        _ cohabitantId: String
    ) async throws -> Void

    /// カスタムカテゴリの削除
    /// - Note: カテゴリを指している家事は書き換えない。表示時に「その他」として扱う
    public let deleteCategory: @Sendable (_ id: String, _ cohabitantId: String) async throws -> Void

    /// SnapshotListener の解除
    public let removeListener: @Sendable (_ id: String) async -> Void

    public init(
        addItemsSnapshotListener: @Sendable @escaping (
            _ id: String,
            _ cohabitantId: String
        ) async -> AsyncStream<[FrequentHouseworkItem]> = { _, _ in .makeStream().stream },
        addCategoriesSnapshotListener: @Sendable @escaping (
            _ id: String,
            _ cohabitantId: String
        ) async -> AsyncStream<[FrequentHouseworkCustomCategory]> = { _, _ in .makeStream().stream },
        upsertItems: @Sendable @escaping (
            _ items: [FrequentHouseworkItem],
            _ cohabitantId: String
        ) async throws -> Void = { _, _ in },
        deleteItem: @Sendable @escaping (_ id: String, _ cohabitantId: String) async throws -> Void = { _, _ in },
        upsertCategories: @Sendable @escaping (
            _ categories: [FrequentHouseworkCustomCategory],
            _ cohabitantId: String
        ) async throws -> Void = { _, _ in },
        deleteCategory: @Sendable @escaping (_ id: String, _ cohabitantId: String) async throws -> Void = { _, _ in },
        removeListener: @Sendable @escaping (_ id: String) async -> Void = { _ in }
    ) {
        self.addItemsSnapshotListener = addItemsSnapshotListener
        self.addCategoriesSnapshotListener = addCategoriesSnapshotListener
        self.upsertItems = upsertItems
        self.deleteItem = deleteItem
        self.upsertCategories = upsertCategories
        self.deleteCategory = deleteCategory
        self.removeListener = removeListener
    }

}

public extension FrequentHouseworkClient {

    static let previewValue: FrequentHouseworkClient = .init()

}
