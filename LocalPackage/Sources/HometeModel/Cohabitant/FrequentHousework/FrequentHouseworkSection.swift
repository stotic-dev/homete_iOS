//
//  FrequentHouseworkSection.swift
//  LocalPackage
//

/// カテゴリ1つ分の家事の並び
public struct FrequentHouseworkSection: Identifiable, Sendable, Equatable {

    public let category: FrequentHouseworkCategory
    public let items: [FrequentHouseworkItem]

    public var id: String {
        category.id
    }

    public init(category: FrequentHouseworkCategory, items: [FrequentHouseworkItem]) {
        self.category = category
        self.items = items
    }

}
