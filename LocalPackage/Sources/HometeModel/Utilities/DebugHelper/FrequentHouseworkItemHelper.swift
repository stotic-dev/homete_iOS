//
//  FrequentHouseworkItemHelper.swift
//  LocalPackage
//

import Foundation

#if DEBUG

public extension FrequentHouseworkItem {

    /// Preview用のいつもの家事
    /// - Note: 実行日時で表示が変わらないよう、作成・更新日時は固定する
    static func makeForPreview(
        id: String,
        title: String,
        point: Int = 10,
        categoryId: String? = nil,
        sortOrder: Int = 0
    ) -> Self {
        .init(
            id: id,
            title: title,
            point: point,
            categoryId: categoryId,
            sortOrder: sortOrder,
            createdAt: .previewDate(year: 2026, month: 9, day: 1),
            updatedAt: .previewDate(year: 2026, month: 9, day: 1)
        )
    }

}

#endif
