//
//  FrequentHouseworkHelper.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain

extension FrequentHouseworkItem {

    static func makeForTest(
        id: String,
        title: String? = nil,
        point: Int = 10,
        categoryId: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .previewDate(year: 2026, month: 9, day: 1),
        updatedAt: Date = .previewDate(year: 2026, month: 9, day: 1)
    ) -> Self {
        .init(
            id: id,
            title: title ?? "title\(id)",
            point: point,
            categoryId: categoryId,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

}

extension FrequentHouseworkCustomCategory {

    static func makeForTest(
        id: String,
        name: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .previewDate(year: 2026, month: 9, day: 1)
    ) -> Self {
        .init(
            id: id,
            name: name ?? "category\(id)",
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }

}
