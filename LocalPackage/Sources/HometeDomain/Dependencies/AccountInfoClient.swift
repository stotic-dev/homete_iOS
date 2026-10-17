//
//  AccountInfoClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public struct AccountInfoClient: Sendable {

    public let insertOrUpdate: @Sendable (Account) async throws -> Void
    public let fetch: @Sendable (String) async throws -> Account?
    /// FCMトークンを本人だけが読める場所へ保存する
    /// - Note: 旧バージョンのアプリがAccount本体に書いた`fcmToken`も同時に消す
    public let updateFcmToken: @Sendable (_ accountId: String, _ fcmToken: String) async throws -> Void
    /// 自分のアカウントを購読する
    /// - Note: 招待リンク経由の参加ではサーバー側（Cloud Functions）が発行者の`cohabitantId`を更新するため、
    ///         クライアント起点の書き込みだけでは自分のアカウントの変化を検知できない
    public let addSnapshotListener: @Sendable (
        _ listenerId: String,
        _ accountId: String
    ) async -> AsyncThrowingStream<Account?, Error>
    public let removeSnapshotListener: @Sendable (_ listenerId: String) async -> Void

    public init(
        insertOrUpdate: (@Sendable (Account) async throws -> Void)? = nil,
        fetch: (@Sendable (String) async throws -> Account?)? = nil,
        updateFcmToken: (@Sendable (_ accountId: String, _ fcmToken: String) async throws -> Void)? = nil,
        addSnapshotListener: (@Sendable (
            _: String,
            _: String
        ) async -> AsyncThrowingStream<Account?, Error>)? = nil,
        removeSnapshotListener: (@Sendable (_ listenerId: String) async -> Void)? = nil
    ) {
        // デフォルト引数にクロージャを書くと、Xcode 26系（Swift 6.2〜6.3）のビルドで並列に呼ばれたときに
        // asyncフレームが壊れてクラッシュする。そのためデフォルト値はnilにして、既定の実装は本体で代入する
        self.insertOrUpdate = insertOrUpdate ?? { _ in }
        self.fetch = fetch ?? { _ in nil }
        self.updateFcmToken = updateFcmToken ?? { _, _ in }
        self.addSnapshotListener = addSnapshotListener ?? { _, _ in .init { $0.finish() } }
        self.removeSnapshotListener = removeSnapshotListener ?? { _ in }
    }

}

public extension AccountInfoClient {

    static let previewValue: AccountInfoClient = .init()

}
