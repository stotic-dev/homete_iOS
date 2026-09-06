//
//  CohabitantClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/18.
//

public struct CohabitantClient: Sendable {

    public let register: @Sendable (CohabitantData) async throws -> Void
    /// 単一の同居人グループを購読する
    /// - Note: コレクションクエリではなくドキュメント購読にしているのは、Firestoreのセキュリティルールが
    ///         `list` をクエリ内容だけで判定し、ドキュメントの`members`を参照できないため。
    ///         クエリのままだと「メンバーだけが読める」ルールを書けない。
    public let addSnapshotListener: @Sendable (
        _ listenerId: String,
        _ cohabitantId: String
    ) async -> AsyncThrowingStream<CohabitantData?, Error>
    public let removeSnapshotListener: @Sendable (_ listenerId: String) async -> Void

    public init(
        register: @Sendable @escaping (CohabitantData) async throws -> Void = { _ in },
        addSnapshotListener: @Sendable @escaping (
            _: String,
            _: String
        ) async -> AsyncThrowingStream<CohabitantData?, Error> = { _, _ in .init { $0.finish() } },
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
