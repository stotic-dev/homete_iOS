//
//  HouseworkEntryHistoryService.swift
//  LocalPackage
//

import Foundation
import GRDB
import HometeDomain

/// 家事の入力履歴をSQLiteに読み書きするService
public enum HouseworkEntryHistoryService {

    /// 入力履歴を、最後に使ったものが先頭になる順で読み出す
    /// - Note: 読み出しのついでに、旧バージョンが`UserDefaults`に残した履歴の取り込みも済ませる
    public static func fetch() async throws -> HouseworkHistoryList {
        let queue = try await AppDatabase.shared.queue()
        try await importLegacyHistoryIfNeeded(queue)
        let records = try await queue.read { db in
            try HouseworkEntryHistoryRecord
                .order(HouseworkEntryHistoryRecord.Columns.sortOrder)
                .fetchAll(db)
        }
        return .init(items: records.map(\.title))
    }

    /// 入力履歴を並び順ごと保存する
    /// - Note: 履歴から消えたものを残さないため、渡されたリストに無い行は同じトランザクションで削除する
    public static func save(_ list: HouseworkHistoryList) async throws {
        let records = list.items.enumerated().map { index, title in
            HouseworkEntryHistoryRecord(title: title, sortOrder: index)
        }
        let queue = try await AppDatabase.shared.queue()
        try await queue.write { db in
            let keptTitles = records.map(\.title)
            try HouseworkEntryHistoryRecord
                .filter(!keptTitles.contains(HouseworkEntryHistoryRecord.Columns.title))
                .deleteAll(db)
            for record in records {
                try record.save(db)
            }
        }
    }

}

// MARK: - UserDefaultsからの移行

private extension HouseworkEntryHistoryService {

    /// 旧バージョンが`@AppStorage`で保存していた履歴のキー
    static var legacyHistoryKey: String {
        "houseworkEntryHistoryList"
    }

    /// 旧バージョンの履歴が残っていればDBへ取り込み、`UserDefaults`側を削除する
    static func importLegacyHistoryIfNeeded(_ queue: DatabaseQueue) async throws {
        guard let rawValue = UserDefaults.standard.string(forKey: legacyHistoryKey) else { return }
        let titles = decodeLegacyTitles(from: rawValue)
        try await queue.write { db in
            // 取り込み後に削除する前で落ちた場合に二重登録しないよう、まだ1件も無いときだけ取り込む
            guard try HouseworkEntryHistoryRecord.fetchCount(db) == 0 else { return }
            for (index, title) in titles.enumerated() {
                try HouseworkEntryHistoryRecord(title: title, sortOrder: index).insert(db)
            }
        }
        UserDefaults.standard.removeObject(forKey: legacyHistoryKey)
    }

    /// 旧バージョンの履歴（`{"items":["洗濯","掃除"]}`形式のJSON文字列）から家事の名前を取り出す
    /// - Note: 同じ名前が複数あると主キーが衝突するため、並び順を保ったまま重複を落とす
    static func decodeLegacyTitles(from rawValue: String) -> [String] {
        guard let data = rawValue.data(using: .utf8),
              let payload = try? JSONDecoder().decode(LegacyHouseworkHistoryPayload.self, from: data) else {
            return []
        }
        var seen = Set<String>()
        return payload.items.filter { seen.insert($0).inserted }
    }

}

/// 旧バージョンが`UserDefaults`に保存していた履歴のJSON構造
private struct LegacyHouseworkHistoryPayload: Decodable {

    let items: [String]

}
