//
//  FrequentHouseworkContext.swift
//  LocalPackage
//

import Foundation

/// 同居人グループのいつもの家事とカスタムカテゴリ
/// - Note: 画面はこの値からセクション・絞り込みのカテゴリ・名前の重複を判定する
public struct FrequentHouseworkContext: Sendable, Equatable {

    public let items: [FrequentHouseworkItem]
    public let customCategories: [FrequentHouseworkCustomCategory]

    public init(
        items: [FrequentHouseworkItem] = [],
        customCategories: [FrequentHouseworkCustomCategory] = []
    ) {
        self.items = items
        self.customCategories = customCategories
    }

    /// いつもの家事が1件も登録されていないか
    public var isEmpty: Bool {
        items.isEmpty
    }

    /// 表示順（プリセット → カスタム → その他）のカテゴリ
    /// - Note: 家事が0件のカテゴリも含む。絞り込みのチップやカテゴリの選択肢に使う
    public var categories: [FrequentHouseworkCategory] {
        let presets = PresetFrequentHouseworkCategory.allCases.map { FrequentHouseworkCategory.preset($0) }
        let customs = sortedCustomCategories.map { FrequentHouseworkCategory.custom($0) }
        return presets + customs + [FrequentHouseworkCategory.uncategorized]
    }

    /// 並べ替え順のカスタムカテゴリ
    public var sortedCustomCategories: [FrequentHouseworkCustomCategory] {
        customCategories.sorted { lhs, rhs in
            (lhs.sortOrder, lhs.createdAt, lhs.id) < (rhs.sortOrder, rhs.createdAt, rhs.id)
        }
    }

    /// 家事があるカテゴリだけを表示順に並べたセクション
    public var sections: [FrequentHouseworkSection] {
        categories.compactMap { category -> FrequentHouseworkSection? in
            let sectionItems = sortedItems(in: category)
            guard !sectionItems.isEmpty else { return nil }
            return FrequentHouseworkSection(category: category, items: sectionItems)
        }
    }

    /// 表示順（カテゴリの表示順 → カテゴリ内の並び順）に並べた全件
    public var orderedItems: [FrequentHouseworkItem] {
        sections.flatMap(\.items)
    }

    /// 家事が属するカテゴリ。未設定・削除済みのカテゴリは「その他」になる
    public func category(of item: FrequentHouseworkItem) -> FrequentHouseworkCategory {
        category(forId: item.categoryId)
    }

    /// 指定カテゴリの家事を並び順で返す
    public func sortedItems(in category: FrequentHouseworkCategory) -> [FrequentHouseworkItem] {
        items
            .filter { self.category(of: $0) == category }
            .sorted { lhs, rhs in
                (lhs.sortOrder, lhs.createdAt, lhs.id) < (rhs.sortOrder, rhs.createdAt, rhs.id)
            }
    }

    /// 指定カテゴリの末尾に追加するときの並び順
    public func nextSortOrder(forCategoryId categoryId: String?) -> Int {
        let sortOrders = sortedItems(in: category(forId: categoryId)).map(\.sortOrder)
        return (sortOrders.max() ?? -1) + 1
    }

    /// 同じ名前のいつもの家事があるか（前後の空白を除いて比較する）
    /// - Parameter excludingId: 編集中の家事自身を比較対象から外すためのID
    public func containsTitle(_ title: String, excludingId: String? = nil) -> Bool {
        let normalizedTitle = Self.normalize(title)
        return items.contains { $0.id != excludingId && Self.normalize($0.title) == normalizedTitle }
    }

    /// 同じ名前のカテゴリがあるか（プリセット・「その他」を含め、前後の空白を除いて比較する）
    /// - Parameter excludingId: 名前を変更中のカテゴリ自身を比較対象から外すためのID
    public func containsCategoryName(_ name: String, excludingId: String? = nil) -> Bool {
        let normalizedName = Self.normalize(name)
        let reservedNames = PresetFrequentHouseworkCategory.allCases.map(\.name)
            + [FrequentHouseworkCategory.uncategorizedName]
        if reservedNames.contains(normalizedName) {
            return true
        }
        return customCategories.contains { $0.id != excludingId && Self.normalize($0.name) == normalizedName }
    }

    /// テンプレートの家事から、取り込みの候補を作る
    /// - Note: 曜日は月曜始まりの順で走査し、名前が重複する家事は最初に見つかったものの名前・ポイントを使う
    public func importCandidates(from days: [HouseworkTemplateDay]) -> [FrequentHouseworkImportCandidate] {
        var candidates: [FrequentHouseworkImportCandidate] = []
        var foundTitles: Set<String> = []
        for dayOfWeek in DayOfWeek.displayOrdered {
            let dayItems = days.first { $0.dayOfWeek == dayOfWeek }?.items ?? []
            for item in dayItems {
                let normalizedTitle = Self.normalize(item.title)
                guard !normalizedTitle.isEmpty, !foundTitles.contains(normalizedTitle) else { continue }
                foundTitles.insert(normalizedTitle)
                candidates.append(.init(
                    title: normalizedTitle,
                    point: item.point,
                    isAlreadyRegistered: containsTitle(normalizedTitle)
                ))
            }
        }
        return candidates
    }

    /// 名前の比較・保存に使う形にそろえる（前後の空白・改行を除く）
    public static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// いつもの家事だけを差し替えた値を返す
    public func replacingItems(_ items: [FrequentHouseworkItem]) -> FrequentHouseworkContext {
        .init(items: items, customCategories: customCategories)
    }

    /// カスタムカテゴリだけを差し替えた値を返す
    public func replacingCustomCategories(
        _ customCategories: [FrequentHouseworkCustomCategory]
    ) -> FrequentHouseworkContext {
        .init(items: items, customCategories: customCategories)
    }

}

private extension FrequentHouseworkContext {

    func category(forId categoryId: String?) -> FrequentHouseworkCategory {
        guard let categoryId else { return .uncategorized }
        if let preset = PresetFrequentHouseworkCategory(rawValue: categoryId) {
            return .preset(preset)
        }
        if let custom = customCategories.first(where: { $0.id == categoryId }) {
            return .custom(custom)
        }
        return .uncategorized
    }

}
