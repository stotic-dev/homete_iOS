//
//  FrequentHouseworkCustomCategoryHelper.swift
//  LocalPackage
//

import Foundation

#if DEBUG

public extension FrequentHouseworkCustomCategory {

    /// Preview用のカスタムカテゴリ
    /// - Note: 実行日時で並び順が変わらないよう、作成日時は固定する
    static func makeForPreview(
        id: String,
        name: String,
        sortOrder: Int = 0
    ) -> Self {
        .init(
            id: id,
            name: name,
            sortOrder: sortOrder,
            createdAt: .previewDate(year: 2026, month: 9, day: 1)
        )
    }

}

#endif
