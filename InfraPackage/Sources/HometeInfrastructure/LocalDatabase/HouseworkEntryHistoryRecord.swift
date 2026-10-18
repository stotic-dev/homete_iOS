//
//  HouseworkEntryHistoryRecord.swift
//  LocalPackage
//

import GRDB

/// 家事の入力履歴1件のレコード
struct HouseworkEntryHistoryRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = "houseworkEntryHistory"

    let title: String
    let point: Int
    /// 表示順。0が先頭（＝最後に使ったもの）
    let sortOrder: Int

}

extension HouseworkEntryHistoryRecord {

    enum Columns {

        static let title = Column(CodingKeys.title)
        static let sortOrder = Column(CodingKeys.sortOrder)

    }

}
