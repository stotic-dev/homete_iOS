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

// MARK: - 名前の検証

public extension FrequentHouseworkContext {

    /// いつもの家事の名前を検証する
    /// - Parameter excludingId: 編集中の家事自身を比較対象から外すためのID
    func validateTitle(_ title: String, excludingId: String? = nil) -> TitleValidation {
        let normalizedTitle = Self.normalize(title)
        guard !normalizedTitle.isEmpty else { return .emptyTitle }
        guard !containsTitle(normalizedTitle, excludingId: excludingId) else { return .duplicatedTitle }
        return .valid(normalizedTitle)
    }

    /// 検証を通ったいつもの家事の名前（前後の空白を除いたもの）
    /// - Throws: 名前が空・重複の場合は`FrequentHouseworkError`
    func validatedTitle(_ title: String, excludingId: String? = nil) throws -> String {
        switch validateTitle(title, excludingId: excludingId) {
        case let .valid(normalizedTitle):
            return normalizedTitle

        case .emptyTitle:
            throw FrequentHouseworkError.emptyTitle

        case .duplicatedTitle:
            throw FrequentHouseworkError.duplicatedTitle
        }
    }

    /// 検証を通ったカスタムカテゴリの名前（前後の空白を除いたもの）
    /// - Throws: 名前が空・重複の場合は`FrequentHouseworkError`
    func validatedCategoryName(_ name: String, excludingId: String? = nil) throws -> String {
        let normalizedName = Self.normalize(name)
        guard !normalizedName.isEmpty else { throw FrequentHouseworkError.emptyCategoryName }
        guard !containsCategoryName(normalizedName, excludingId: excludingId) else {
            throw FrequentHouseworkError.duplicatedCategoryName
        }
        return normalizedName
    }

}

public extension FrequentHouseworkContext {

    /// いつもの家事の名前の検証結果
    /// - Note: 決定ボタンの非活性（画面）と書き込み前の検証（Store）で同じ判定を使うため、
    ///         エラーではなく結果の値として返す
    enum TitleValidation: Equatable, Sendable {

        /// 決定できる（前後の空白を除いた名前）
        case valid(String)
        /// 名前が空
        case emptyTitle
        /// 同じ名前のいつもの家事がすでにある
        case duplicatedTitle

        public var isValid: Bool {
            if case .valid = self { true } else { false }
        }

    }

}

// MARK: - 書き込むデータの組み立て

public extension FrequentHouseworkContext {

    /// 入力から追加するいつもの家事を組み立てる
    /// - Note: 名前の重複と並び順は、先に組み立てた家事も含めて判定する。各カテゴリの末尾に、入力の順で並べる
    /// - Throws: 名前が空・重複（入力同士の重複を含む）の場合、上限を超える場合は`FrequentHouseworkError`
    func makeAddedItems(
        from inputs: [FrequentHouseworkInput],
        limitPolicy: FrequentHouseworkLimitPolicy,
        timestamp: Date,
        idGenerator: () -> String
    ) throws -> [FrequentHouseworkItem] {
        guard limitPolicy.canAdd(inputs.count, currentCount: items.count) else {
            throw FrequentHouseworkError.limitExceeded
        }
        var newItems: [FrequentHouseworkItem] = []
        for input in inputs {
            let workingContext = replacingItems(items + newItems)
            let validTitle = try workingContext.validatedTitle(input.title)
            newItems.append(.init(
                id: idGenerator(),
                title: validTitle,
                point: input.point,
                categoryId: input.categoryId,
                sortOrder: workingContext.nextSortOrder(forCategoryId: input.categoryId),
                createdAt: timestamp,
                updatedAt: timestamp
            ))
        }
        return newItems
    }

    /// 編集後のいつもの家事を組み立てる
    /// - Returns: 対象の家事がない場合は`nil`（編集中に同居人が削除したものを復活させないため）
    /// - Note: カテゴリを変えた場合は、移動先のカテゴリの末尾に並べる
    /// - Throws: 名前が空・重複の場合は`FrequentHouseworkError`
    func makeUpdatedItem(
        itemId: String,
        input: FrequentHouseworkInput,
        timestamp: Date
    ) throws -> FrequentHouseworkItem? {
        guard let current = items.first(where: { $0.id == itemId }) else { return nil }
        let validTitle = try validatedTitle(input.title, excludingId: itemId)
        let isSameCategory = category(of: current).categoryId == input.categoryId
        return .init(
            id: current.id,
            title: validTitle,
            point: input.point,
            categoryId: input.categoryId,
            sortOrder: isSameCategory ? current.sortOrder : nextSortOrder(forCategoryId: input.categoryId),
            createdAt: current.createdAt,
            updatedAt: timestamp
        )
    }

    /// 並べ替えで書き込みが必要ないつもの家事だけを組み立てる
    /// - Parameter orderedIds: 並べ替え後の順に並べた、1つのカテゴリの家事ID
    func makeReorderedItems(orderedIds: [String]) -> [FrequentHouseworkItem] {
        orderedIds.enumerated().compactMap { index, id -> FrequentHouseworkItem? in
            guard let item = items.first(where: { $0.id == id }), item.sortOrder != index else { return nil }
            return .init(
                id: item.id,
                title: item.title,
                point: item.point,
                categoryId: item.categoryId,
                sortOrder: index,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt
            )
        }
    }

    /// 追加するカスタムカテゴリを組み立てる
    /// - Note: カスタムカテゴリの末尾に並べる
    /// - Throws: 名前が空・重複の場合は`FrequentHouseworkError`
    func makeAddedCategory(
        name: String,
        id: String,
        createdAt: Date
    ) throws -> FrequentHouseworkCustomCategory {
        let validName = try validatedCategoryName(name)
        return .init(
            id: id,
            name: validName,
            sortOrder: nextCategorySortOrder,
            createdAt: createdAt
        )
    }

    /// 名前を変更したカスタムカテゴリを組み立てる
    /// - Returns: 対象のカテゴリがない場合は`nil`（編集中に同居人が削除したものを復活させないため）
    /// - Throws: 名前が空・重複の場合は`FrequentHouseworkError`
    func makeRenamedCategory(id: String, name: String) throws -> FrequentHouseworkCustomCategory? {
        guard let current = customCategories.first(where: { $0.id == id }) else { return nil }
        let validName = try validatedCategoryName(name, excludingId: id)
        return .init(
            id: current.id,
            name: validName,
            sortOrder: current.sortOrder,
            createdAt: current.createdAt
        )
    }

    /// 並べ替えで書き込みが必要なカスタムカテゴリだけを組み立てる
    /// - Parameter orderedIds: 並べ替え後の順に並べたカスタムカテゴリのID
    func makeReorderedCategories(orderedIds: [String]) -> [FrequentHouseworkCustomCategory] {
        orderedIds.enumerated().compactMap { index, id -> FrequentHouseworkCustomCategory? in
            guard let category = customCategories.first(where: { $0.id == id }),
                  category.sortOrder != index else { return nil }
            return .init(id: category.id, name: category.name, sortOrder: index, createdAt: category.createdAt)
        }
    }

    /// カスタムカテゴリを末尾に追加するときの並び順
    var nextCategorySortOrder: Int {
        (customCategories.map(\.sortOrder).max() ?? -1) + 1
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
