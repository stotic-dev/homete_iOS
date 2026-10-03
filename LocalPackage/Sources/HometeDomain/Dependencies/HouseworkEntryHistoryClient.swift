//
//  HouseworkEntryHistoryClient.swift
//  LocalPackage
//

/// 家事の入力履歴を端末内のSQLiteに永続化するClient
/// - Note: 履歴は端末ごとの入力補助であり、同居人グループで共有しない。そのためFirestoreではなく端末内のDBに置く
public struct HouseworkEntryHistoryClient: Sendable {

    /// 保存されている入力履歴を、新しく使ったものが先頭になる順で読み出す
    public let fetch: @Sendable () async throws -> HouseworkHistoryList

    /// 入力履歴を並び順ごと保存する
    public let save: @Sendable (_ list: HouseworkHistoryList) async throws -> Void

    public init(
        fetch: (@Sendable () async throws -> HouseworkHistoryList)? = nil,
        save: (@Sendable (_ list: HouseworkHistoryList) async throws -> Void)? = nil
    ) {
        // デフォルト引数にクロージャを書くと、Xcode 26系（Swift 6.2〜6.3）のビルドで並列に呼ばれたときに
        // asyncフレームが壊れてクラッシュする。そのためデフォルト値はnilにして、既定の実装は本体で代入する
        self.fetch = fetch ?? { .init(items: []) }
        self.save = save ?? { _ in }
    }

}

public extension HouseworkEntryHistoryClient {

    static let previewValue: HouseworkEntryHistoryClient = .init()

}
