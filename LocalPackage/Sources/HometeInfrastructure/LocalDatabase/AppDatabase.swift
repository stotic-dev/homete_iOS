//
//  AppDatabase.swift
//  LocalPackage
//

import Foundation
import GRDB

/// 端末内のSQLiteデータベース
/// - Note: 開くのとマイグレーションの適用は初回アクセス時に1度だけ行う。
///         同居人グループで共有しない端末ローカルのデータ（家事の入力履歴など）を置く
public actor AppDatabase {

    public static let shared = AppDatabase()

    private var openedQueue: DatabaseQueue?

    private init() {}

    /// 読み書きに使うキュー
    /// - Note: `DatabaseQueue`自体が書き込みを直列化するため、呼び出し側はこれを受け取って
    ///         actor外で読み書きしてよい（DBアクセスをこのactorに集約すると待ちが直列になるため避けている）
    public func queue() throws -> DatabaseQueue {
        if let openedQueue {
            return openedQueue
        }
        let queue = try DatabaseQueue(path: Self.databaseURL().path)
        try Self.migrator.migrate(queue)
        openedQueue = queue
        return queue
    }

}

private extension AppDatabase {

    /// データベースファイルの置き場所
    /// - Note: ユーザーが直接触るものではないため、Documentsではなく Application Support 配下に置く
    static func databaseURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("Database", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("homete.sqlite")
    }

    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createHouseworkEntryHistory") { db in
            try db.create(table: HouseworkEntryHistoryRecord.databaseTableName) { table in
                // 履歴の同一性は家事の名前で見るため、名前をそのまま主キーにする
                table.primaryKey("title", .text)
                table.column("sortOrder", .integer).notNull()
            }
        }
        return migrator
    }

}
