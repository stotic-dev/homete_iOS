//
//  FrequentHouseworkContextAssemblyTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

/// `FrequentHouseworkContext`のうち、名前の検証と書き込むデータの組み立てを検証する
enum FrequentHouseworkContextAssemblyTest {

    struct ValidateTitleCase {}
    struct ValidateCategoryNameCase {}
    struct MakeAddedItemsCase {}
    struct MakeUpdatedItemCase {}
    struct MakeReorderedItemsCase {}
    struct MakeCategoryCase {}
    struct MemoCase {}

    static let fixedNow = Date.previewDate(year: 2026, month: 9, day: 26)
    static let memo = HouseworkMemo(
        text: "スーパーで",
        checklist: [.init(id: "1", title: "牛乳", isChecked: false)]
    )

}

// MARK: - 名前の検証

extension FrequentHouseworkContextAssemblyTest.ValidateTitleCase {

    @Test(
        "名前が空なら空、既存と重複するなら重複、それ以外は前後の空白を除いた名前を返す",
        arguments: [
            ("  ", FrequentHouseworkContext.TitleValidation.emptyTitle),
            ("洗濯 ", FrequentHouseworkContext.TitleValidation.duplicatedTitle),
            (" 布団干し ", FrequentHouseworkContext.TitleValidation.valid("布団干し")),
        ]
    )
    func validateTitle(title: String, expected: FrequentHouseworkContext.TitleValidation) {
        // Arrange

        let context = FrequentHouseworkContext(items: [.makeForTest(id: "1", title: "洗濯")])

        // Act

        let actual = context.validateTitle(title)

        // Assert

        #expect(actual == expected)
    }

    @Test("編集中の家事自身と同じ名前のままなら、決定できると判定する")
    func validateTitleIgnoresEditingItself() {
        // Arrange

        let context = FrequentHouseworkContext(items: [.makeForTest(id: "1", title: "洗濯")])

        // Act

        let actual = context.validateTitle("洗濯", excludingId: "1")

        // Assert

        #expect(actual == .valid("洗濯"))
    }

}

extension FrequentHouseworkContextAssemblyTest.ValidateCategoryNameCase {

    @Test(
        "名前が空なら空、プリセット・「その他」・既存のカスタムと重複するなら重複、それ以外は前後の空白を除いた名前を返す",
        arguments: [
            ("  ", FrequentHouseworkContext.CategoryNameValidation.emptyName),
            ("掃除", FrequentHouseworkContext.CategoryNameValidation.duplicatedName),
            ("その他", FrequentHouseworkContext.CategoryNameValidation.duplicatedName),
            ("ペット ", FrequentHouseworkContext.CategoryNameValidation.duplicatedName),
            (" 庭 ", FrequentHouseworkContext.CategoryNameValidation.valid("庭")),
        ]
    )
    func validateCategoryName(name: String, expected: FrequentHouseworkContext.CategoryNameValidation) {
        // Arrange

        let context = FrequentHouseworkContext(
            customCategories: [.makeForTest(id: "1", name: "ペット")]
        )

        // Act

        let actual = context.validateCategoryName(name)

        // Assert

        #expect(actual == expected)
    }

    @Test("名前を変更中のカテゴリ自身と同じ名前のままなら、決定できると判定する")
    func validateCategoryNameIgnoresEditingItself() {
        // Arrange

        let context = FrequentHouseworkContext(
            customCategories: [.makeForTest(id: "1", name: "ペット")]
        )

        // Act

        let actual = context.validateCategoryName("ペット", excludingId: "1")

        // Assert

        #expect(actual == .valid("ペット"))
    }

}

// MARK: - 追加する家事の組み立て

extension FrequentHouseworkContextAssemblyTest.MakeAddedItemsCase {

    @Test("名前の前後の空白を除き、各カテゴリの末尾の並び順で、入力の順に組み立てる")
    func makeAddedItemsPlacesItemsAtEndOfEachCategory() throws {
        // Arrange

        let now = FrequentHouseworkContextAssemblyTest.fixedNow
        let generatedIds = TestBox(value: ["new1", "new2", "new3"])
        let context = FrequentHouseworkContext(
            items: [.makeForTest(id: "existing", categoryId: "preset.cleaning", sortOrder: 2)]
        )
        let expected: [FrequentHouseworkItem] = [
            .init(
                id: "new1",
                title: "風呂掃除",
                point: 20,
                categoryId: "preset.cleaning",
                sortOrder: 3,
                createdAt: now,
                updatedAt: now
            ),
            .init(
                id: "new2",
                title: "窓拭き",
                point: 30,
                categoryId: "preset.cleaning",
                sortOrder: 4,
                createdAt: now,
                updatedAt: now
            ),
            .init(id: "new3", title: "買い出し", point: 10, categoryId: nil, sortOrder: 0, createdAt: now, updatedAt: now),
        ]

        // Act

        let actual = try context.makeAddedItems(
            from: [
                .init(title: " 風呂掃除 ", point: 20, categoryId: "preset.cleaning"),
                .init(title: "窓拭き", point: 30, categoryId: "preset.cleaning"),
                .init(title: "買い出し", point: 10, categoryId: nil),
            ],
            limitPolicy: .premium,
            timestamp: now,
            idGenerator: { generatedIds.value.removeFirst() }
        )

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "名前が空・既存と重複・入力同士で重複している場合は、エラーを返す",
        arguments: [
            ([FrequentHouseworkInput(title: "  ", point: 10, categoryId: nil)], FrequentHouseworkError.emptyTitle),
            ([FrequentHouseworkInput(title: "洗濯", point: 10, categoryId: nil)], FrequentHouseworkError.duplicatedTitle),
            (
                [
                    FrequentHouseworkInput(title: "窓拭き", point: 10, categoryId: nil),
                    FrequentHouseworkInput(title: "窓拭き ", point: 20, categoryId: nil),
                ],
                FrequentHouseworkError.duplicatedTitle
            ),
        ]
    )
    func makeAddedItemsWithInvalidTitleThrows(
        inputs: [FrequentHouseworkInput],
        expectedError: FrequentHouseworkError
    ) {
        // Arrange

        let context = FrequentHouseworkContext(items: [.makeForTest(id: "1", title: "洗濯")])

        // Act & Assert

        #expect(throws: expectedError) {
            try context.makeAddedItems(
                from: inputs,
                limitPolicy: .premium,
                timestamp: FrequentHouseworkContextAssemblyTest.fixedNow,
                idGenerator: { "new" }
            )
        }
    }

    @Test("無料プランで上限を超える場合は、limitExceededを返す")
    func makeAddedItemsOverLimitThrows() {
        // Arrange

        let context = FrequentHouseworkContext(
            items: (0 ..< 9).map { .makeForTest(id: "\($0)", sortOrder: $0) }
        )

        // Act & Assert

        #expect(throws: FrequentHouseworkError.limitExceeded) {
            try context.makeAddedItems(
                from: [
                    .init(title: "風呂掃除", point: 10, categoryId: nil),
                    .init(title: "窓拭き", point: 10, categoryId: nil),
                ],
                limitPolicy: .free,
                timestamp: FrequentHouseworkContextAssemblyTest.fixedNow,
                idGenerator: { "new" }
            )
        }
    }

}

// MARK: - 編集後の家事の組み立て

extension FrequentHouseworkContextAssemblyTest.MakeUpdatedItemCase {

    @Test("カテゴリを変えない場合は、並び順と作成日時を保ったまま内容と更新日時を差し替える")
    func makeUpdatedItemInSameCategoryKeepsSortOrder() throws {
        // Arrange

        let now = FrequentHouseworkContextAssemblyTest.fixedNow
        let current = FrequentHouseworkItem.makeForTest(
            id: "1",
            title: "風呂",
            point: 10,
            categoryId: "preset.cleaning",
            sortOrder: 3
        )
        let context = FrequentHouseworkContext(items: [current])
        let expected = FrequentHouseworkItem(
            id: "1",
            title: "風呂掃除",
            point: 20,
            categoryId: "preset.cleaning",
            sortOrder: 3,
            createdAt: current.createdAt,
            updatedAt: now
        )

        // Act

        let actual = try context.makeUpdatedItem(
            itemId: "1",
            input: .init(title: "風呂掃除", point: 20, categoryId: "preset.cleaning"),
            timestamp: now
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("カテゴリを変える場合は、移動先のカテゴリの末尾に並べる")
    func makeUpdatedItemToOtherCategoryMovesToEnd() throws {
        // Arrange

        let now = FrequentHouseworkContextAssemblyTest.fixedNow
        let current = FrequentHouseworkItem.makeForTest(id: "1", title: "布団干し", categoryId: nil, sortOrder: 0)
        let laundry = FrequentHouseworkItem.makeForTest(
            id: "2",
            title: "洗濯",
            categoryId: "preset.laundry",
            sortOrder: 4
        )
        let context = FrequentHouseworkContext(items: [current, laundry])
        let expected = FrequentHouseworkItem(
            id: "1",
            title: "布団干し",
            point: 10,
            categoryId: "preset.laundry",
            sortOrder: 5,
            createdAt: current.createdAt,
            updatedAt: now
        )

        // Act

        let actual = try context.makeUpdatedItem(
            itemId: "1",
            input: .init(title: "布団干し", point: 10, categoryId: "preset.laundry"),
            timestamp: now
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("ほかの家事と同じ名前にしようとすると、duplicatedTitleを返す")
    func makeUpdatedItemToDuplicatedTitleThrows() {
        // Arrange

        let context = FrequentHouseworkContext(items: [
            .makeForTest(id: "1", title: "風呂"),
            .makeForTest(id: "2", title: "洗濯"),
        ])

        // Act & Assert

        #expect(throws: FrequentHouseworkError.duplicatedTitle) {
            try context.makeUpdatedItem(
                itemId: "1",
                input: .init(title: "洗濯", point: 10, categoryId: nil),
                timestamp: FrequentHouseworkContextAssemblyTest.fixedNow
            )
        }
    }

    @Test("対象の家事がすでに削除されている場合は、復活させないようnilを返す")
    func makeUpdatedItemForDeletedItemIsNil() throws {
        // Arrange

        let context = FrequentHouseworkContext()

        // Act

        let actual = try context.makeUpdatedItem(
            itemId: "deleted",
            input: .init(title: "風呂", point: 10, categoryId: nil),
            timestamp: FrequentHouseworkContextAssemblyTest.fixedNow
        )

        // Assert

        #expect(actual == nil)
    }

}

// MARK: - 並べ替えの組み立て

extension FrequentHouseworkContextAssemblyTest.MakeReorderedItemsCase {

    @Test("並び順が変わった家事だけを、新しい並び順で組み立てる")
    func makeReorderedItemsContainsOnlyChangedItems() {
        // Arrange

        let context = FrequentHouseworkContext(items: [
            .makeForTest(id: "1", sortOrder: 0),
            .makeForTest(id: "2", sortOrder: 1),
            .makeForTest(id: "3", sortOrder: 2),
        ])
        let expected: [FrequentHouseworkItem] = [
            .makeForTest(id: "3", sortOrder: 1),
            .makeForTest(id: "2", sortOrder: 2),
        ]

        // Act

        let actual = context.makeReorderedItems(orderedIds: ["1", "3", "2"])

        // Assert

        #expect(actual == expected)
    }

}

// MARK: - カスタムカテゴリの組み立て

extension FrequentHouseworkContextAssemblyTest.MakeCategoryCase {

    @Test("カテゴリを追加すると、名前の前後の空白を除き、カスタムカテゴリの末尾の並び順で組み立てる")
    func makeAddedCategoryPlacesCategoryAtEnd() throws {
        // Arrange

        let now = FrequentHouseworkContextAssemblyTest.fixedNow
        let context = FrequentHouseworkContext(
            customCategories: [.makeForTest(id: "pet", name: "ペット", sortOrder: 2)]
        )
        let expected = FrequentHouseworkCustomCategory(id: "new", name: "子ども", sortOrder: 3, createdAt: now)

        // Act

        let actual = try context.makeAddedCategory(name: " 子ども ", id: "new", createdAt: now)

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "カテゴリ名が空・プリセットや「その他」・既存のカスタムと重複する場合は、エラーを返す",
        arguments: [
            (" ", FrequentHouseworkError.emptyCategoryName),
            ("洗濯", FrequentHouseworkError.duplicatedCategoryName),
            ("その他", FrequentHouseworkError.duplicatedCategoryName),
            ("ペット", FrequentHouseworkError.duplicatedCategoryName),
        ]
    )
    func makeAddedCategoryWithInvalidNameThrows(name: String, expectedError: FrequentHouseworkError) {
        // Arrange

        let context = FrequentHouseworkContext(customCategories: [.makeForTest(id: "pet", name: "ペット")])

        // Act & Assert

        #expect(throws: expectedError) {
            try context.makeAddedCategory(
                name: name,
                id: "new",
                createdAt: FrequentHouseworkContextAssemblyTest.fixedNow
            )
        }
    }

    @Test("カテゴリ名を変更すると、並び順と作成日時を保ったまま名前を差し替える")
    func makeRenamedCategoryKeepsOrder() throws {
        // Arrange

        let current = FrequentHouseworkCustomCategory.makeForTest(id: "pet", name: "ペット", sortOrder: 1)
        let context = FrequentHouseworkContext(customCategories: [current])
        let expected = FrequentHouseworkCustomCategory(
            id: "pet",
            name: "ペットのお世話",
            sortOrder: 1,
            createdAt: current.createdAt
        )

        // Act

        let actual = try context.makeRenamedCategory(id: "pet", name: "ペットのお世話")

        // Assert

        #expect(actual == expected)
    }

    @Test("対象のカテゴリがすでに削除されている場合は、復活させないようnilを返す")
    func makeRenamedCategoryForDeletedCategoryIsNil() throws {
        // Arrange

        let context = FrequentHouseworkContext()

        // Act

        let actual = try context.makeRenamedCategory(id: "deleted", name: "ペット")

        // Assert

        #expect(actual == nil)
    }

    @Test("並び順が変わったカテゴリだけを、新しい並び順で組み立てる")
    func makeReorderedCategoriesContainsOnlyChangedCategories() {
        // Arrange

        let context = FrequentHouseworkContext(customCategories: [
            .makeForTest(id: "a", sortOrder: 0),
            .makeForTest(id: "b", sortOrder: 1),
            .makeForTest(id: "c", sortOrder: 2),
        ])
        let expected: [FrequentHouseworkCustomCategory] = [
            .makeForTest(id: "b", sortOrder: 0),
            .makeForTest(id: "a", sortOrder: 1),
        ]

        // Act

        let actual = context.makeReorderedCategories(orderedIds: ["b", "a", "c"])

        // Assert

        #expect(actual == expected)
    }

}

// MARK: - メモの引き継ぎ

extension FrequentHouseworkContextAssemblyTest.MemoCase {

    @Test("追加する家事は、入力したメモを持つ")
    func makeAddedItemsKeepsMemo() throws {
        // Arrange

        let now = FrequentHouseworkContextAssemblyTest.fixedNow
        let context = FrequentHouseworkContext()
        let expected: [FrequentHouseworkItem] = [
            .init(
                id: "new",
                title: "買い出し",
                point: 10,
                categoryId: nil,
                sortOrder: 0,
                createdAt: now,
                updatedAt: now,
                memo: FrequentHouseworkContextAssemblyTest.memo
            ),
        ]

        // Act

        let actual = try context.makeAddedItems(
            from: [.init(title: "買い出し", point: 10, categoryId: nil, memo: FrequentHouseworkContextAssemblyTest.memo)],
            limitPolicy: .premium,
            timestamp: now,
            idGenerator: { "new" }
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("編集後の家事は、入力したメモに差し替わる")
    func makeUpdatedItemReplacesMemo() throws {
        // Arrange

        let now = FrequentHouseworkContextAssemblyTest.fixedNow
        let current = FrequentHouseworkItem.makeForTest(
            id: "1",
            title: "買い出し",
            memo: .init(text: "古いメモ", checklist: [])
        )
        let context = FrequentHouseworkContext(items: [current])
        let expected = FrequentHouseworkItem(
            id: "1",
            title: "買い出し",
            point: 10,
            categoryId: nil,
            sortOrder: 0,
            createdAt: current.createdAt,
            updatedAt: now,
            memo: FrequentHouseworkContextAssemblyTest.memo
        )

        // Act

        let actual = try context.makeUpdatedItem(
            itemId: "1",
            input: .init(title: "買い出し", point: 10, categoryId: nil, memo: FrequentHouseworkContextAssemblyTest.memo),
            timestamp: now
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("メモに触れずに編集すると、編集中に同居人が付けたメモを残す")
    func makeUpdatedItemWithoutMemoKeepsLatestMemo() throws {
        // Arrange

        let now = FrequentHouseworkContextAssemblyTest.fixedNow
        let current = FrequentHouseworkItem.makeForTest(
            id: "1",
            title: "買い出し",
            memo: FrequentHouseworkContextAssemblyTest.memo
        )
        let context = FrequentHouseworkContext(items: [current])
        let expected = FrequentHouseworkItem(
            id: "1",
            title: "買い物",
            point: 10,
            categoryId: nil,
            sortOrder: 0,
            createdAt: current.createdAt,
            updatedAt: now,
            memo: FrequentHouseworkContextAssemblyTest.memo
        )

        // Act

        let actual = try context.makeUpdatedItem(
            itemId: "1",
            input: .init(title: "買い物", point: 10, categoryId: nil),
            timestamp: now
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("並べ替えても、メモは引き継がれる")
    func makeReorderedItemsKeepsMemo() {
        // Arrange

        let context = FrequentHouseworkContext(items: [
            .makeForTest(id: "1", sortOrder: 0),
            .makeForTest(id: "2", sortOrder: 1, memo: FrequentHouseworkContextAssemblyTest.memo),
        ])
        let expected: [FrequentHouseworkItem] = [
            .makeForTest(id: "2", sortOrder: 0, memo: FrequentHouseworkContextAssemblyTest.memo),
            .makeForTest(id: "1", sortOrder: 1),
        ]

        // Act

        let actual = context.makeReorderedItems(orderedIds: ["2", "1"])

        // Assert

        #expect(actual == expected)
    }

}
