//
//  FrequentHouseworkContextTest.swift
//  LocalPackage
//

// swiftlint:disable file_length

import Foundation
@testable import HometeDomain
import Testing

enum FrequentHouseworkContextTest {

    struct CategoriesCase {}
    struct SectionsCase {}
    struct NextSortOrderCase {}
    struct ContainsTitleCase {}
    struct ContainsCategoryNameCase {}
    struct ImportCandidatesCase {}

}

extension FrequentHouseworkContextTest.CategoriesCase {

    @Test("カテゴリはプリセット・並べ替え順のカスタム・その他の順に並ぶ")
    func categoriesAreOrderedPresetCustomUncategorized() {
        // Arrange

        let customA = FrequentHouseworkCustomCategory.makeForTest(id: "a", sortOrder: 1)
        let customB = FrequentHouseworkCustomCategory.makeForTest(id: "b", sortOrder: 0)
        let context = FrequentHouseworkContext(items: [], customCategories: [customA, customB])
        let expected: [FrequentHouseworkCategory] = [
            .preset(.cleaning),
            .preset(.laundry),
            .preset(.cooking),
            .preset(.shopping),
            .preset(.garbage),
            .custom(customB),
            .custom(customA),
            .uncategorized,
        ]

        // Act

        let actual = context.categories

        // Assert

        #expect(actual == expected)
    }

}

extension FrequentHouseworkContextTest.SectionsCase {

    @Test("家事があるカテゴリだけを表示順に並べ、カテゴリ内は並び順で並ぶ")
    func sectionsContainOnlyNonEmptyCategoriesInOrder() {
        // Arrange

        let custom = FrequentHouseworkCustomCategory.makeForTest(id: "custom")
        let laundry1 = FrequentHouseworkItem.makeForTest(id: "1", categoryId: "preset.laundry", sortOrder: 1)
        let laundry0 = FrequentHouseworkItem.makeForTest(id: "2", categoryId: "preset.laundry", sortOrder: 0)
        let customItem = FrequentHouseworkItem.makeForTest(id: "3", categoryId: "custom")
        let cleaning = FrequentHouseworkItem.makeForTest(id: "4", categoryId: "preset.cleaning")
        let context = FrequentHouseworkContext(
            items: [laundry1, customItem, laundry0, cleaning],
            customCategories: [custom]
        )
        let expected: [FrequentHouseworkSection] = [
            .init(category: .preset(.cleaning), items: [cleaning]),
            .init(category: .preset(.laundry), items: [laundry0, laundry1]),
            .init(category: .custom(custom), items: [customItem]),
        ]

        // Act

        let actual = context.sections

        // Assert

        #expect(actual == expected)
    }

    @Test("カテゴリ未設定の家事と、削除済みのカテゴリを指す家事は「その他」にまとまる")
    func uncategorizedAndDeletedCategoryItemsAreGroupedAsUncategorized() {
        // Arrange

        let noCategory = FrequentHouseworkItem.makeForTest(id: "1", categoryId: nil, sortOrder: 0)
        let deletedCategory = FrequentHouseworkItem.makeForTest(id: "2", categoryId: "deleted", sortOrder: 1)
        let context = FrequentHouseworkContext(items: [deletedCategory, noCategory], customCategories: [])
        let expected: [FrequentHouseworkSection] = [
            .init(category: .uncategorized, items: [noCategory, deletedCategory]),
        ]

        // Act

        let actual = context.sections

        // Assert

        #expect(actual == expected)
    }

    @Test("並び順が同じ家事は、作成日時の古い順に並ぶ")
    func sameSortOrderItemsAreOrderedByCreatedAt() {
        // Arrange

        let newer = FrequentHouseworkItem.makeForTest(
            id: "1",
            createdAt: .previewDate(year: 2026, month: 9, day: 2)
        )
        let older = FrequentHouseworkItem.makeForTest(
            id: "2",
            createdAt: .previewDate(year: 2026, month: 9, day: 1)
        )
        let context = FrequentHouseworkContext(items: [newer, older], customCategories: [])
        let expected: [FrequentHouseworkSection] = [
            .init(category: .uncategorized, items: [older, newer]),
        ]

        // Act

        let actual = context.sections

        // Assert

        #expect(actual == expected)
    }

    @Test("表示順の全件は、セクションの順に並ぶ")
    func orderedItemsFollowSectionOrder() {
        // Arrange

        let uncategorized = FrequentHouseworkItem.makeForTest(id: "1")
        let garbage = FrequentHouseworkItem.makeForTest(id: "2", categoryId: "preset.garbage")
        let cleaning = FrequentHouseworkItem.makeForTest(id: "3", categoryId: "preset.cleaning")
        let context = FrequentHouseworkContext(items: [uncategorized, garbage, cleaning], customCategories: [])
        let expected = [cleaning, garbage, uncategorized]

        // Act

        let actual = context.orderedItems

        // Assert

        #expect(actual == expected)
    }

}

extension FrequentHouseworkContextTest.NextSortOrderCase {

    @Test("家事がないカテゴリに追加するときの並び順は0")
    func emptyCategoryStartsFromZero() {
        // Arrange

        let context = FrequentHouseworkContext(
            items: [.makeForTest(id: "1", categoryId: "preset.laundry", sortOrder: 5)],
            customCategories: []
        )

        // Act

        let actual = context.nextSortOrder(forCategoryId: "preset.cleaning")

        // Assert

        #expect(actual == 0)
    }

    @Test("家事があるカテゴリに追加するときの並び順は、カテゴリ内の最大値+1")
    func nonEmptyCategoryIsMaxPlusOne() {
        // Arrange

        let context = FrequentHouseworkContext(
            items: [
                .makeForTest(id: "1", categoryId: "preset.cleaning", sortOrder: 3),
                .makeForTest(id: "2", categoryId: "preset.cleaning", sortOrder: 1),
                .makeForTest(id: "3", categoryId: "preset.laundry", sortOrder: 9),
            ],
            customCategories: []
        )

        // Act

        let actual = context.nextSortOrder(forCategoryId: "preset.cleaning")

        // Assert

        #expect(actual == 4)
    }

    @Test("「その他」に追加するときは、削除済みのカテゴリを指す家事も含めて並び順を決める")
    func uncategorizedIncludesDeletedCategoryItems() {
        // Arrange

        let context = FrequentHouseworkContext(
            items: [
                .makeForTest(id: "1", categoryId: nil, sortOrder: 0),
                .makeForTest(id: "2", categoryId: "deleted", sortOrder: 2),
            ],
            customCategories: []
        )

        // Act

        let actual = context.nextSortOrder(forCategoryId: nil)

        // Assert

        #expect(actual == 3)
    }

}

extension FrequentHouseworkContextTest.ContainsTitleCase {

    @Test(
        "前後の空白を除いて同じ名前の家事があるかを判定する",
        arguments: [
            ("風呂掃除", true),
            ("  風呂掃除\n", true),
            ("風呂", false),
        ]
    )
    func containsTitle(input: String, expected: Bool) {
        // Arrange

        let context = FrequentHouseworkContext(
            items: [.makeForTest(id: "1", title: "風呂掃除")],
            customCategories: []
        )

        // Act

        let actual = context.containsTitle(input)

        // Assert

        #expect(actual == expected)
    }

    @Test("編集中の家事自身は、名前の重複判定から外す")
    func excludingIdIsIgnored() {
        // Arrange

        let context = FrequentHouseworkContext(
            items: [.makeForTest(id: "1", title: "風呂掃除")],
            customCategories: []
        )

        // Act

        let actual = context.containsTitle("風呂掃除", excludingId: "1")

        // Assert

        #expect(actual == false)
    }

}

extension FrequentHouseworkContextTest.ContainsCategoryNameCase {

    @Test(
        "プリセット・「その他」・カスタムカテゴリと同じ名前かを判定する",
        arguments: [
            ("掃除", true),
            ("ゴミ", true),
            ("その他", true),
            (" ペット ", true),
            ("子ども", false),
        ]
    )
    func containsCategoryName(input: String, expected: Bool) {
        // Arrange

        let context = FrequentHouseworkContext(
            items: [],
            customCategories: [.makeForTest(id: "pet", name: "ペット")]
        )

        // Act

        let actual = context.containsCategoryName(input)

        // Assert

        #expect(actual == expected)
    }

    @Test("名前を変更中のカテゴリ自身は、名前の重複判定から外す")
    func excludingIdIsIgnored() {
        // Arrange

        let context = FrequentHouseworkContext(
            items: [],
            customCategories: [.makeForTest(id: "pet", name: "ペット")]
        )

        // Act

        let actual = context.containsCategoryName("ペット", excludingId: "pet")

        // Assert

        #expect(actual == false)
    }

}

extension FrequentHouseworkContextTest.ImportCandidatesCase {

    @Test("テンプレートの家事を月曜始まりの順に集め、名前が重複するものは最初に見つかった内容を使う")
    func candidatesAreDeduplicatedInMondayFirstOrder() {
        // Arrange

        let updatedAt = Date.previewDate(year: 2026, month: 9, day: 1)
        let days: [HouseworkTemplateDay] = [
            .init(dayOfWeek: .sunday, items: [
                .init(id: .init(id: "sun"), title: "買い出し", point: 30, updatedAt: updatedAt),
            ]),
            .init(dayOfWeek: .monday, items: [
                .init(id: .init(id: "mon1"), title: "ゴミ出し", point: 10, updatedAt: updatedAt),
                .init(id: .init(id: "mon2"), title: " 洗濯 ", point: 20, updatedAt: updatedAt),
            ]),
            .init(dayOfWeek: .thursday, items: [
                .init(id: .init(id: "thu"), title: "ゴミ出し", point: 99, updatedAt: updatedAt),
            ]),
        ]
        let context = FrequentHouseworkContext(items: [], customCategories: [])
        let expected: [FrequentHouseworkImportCandidate] = [
            .init(title: "ゴミ出し", point: 10, isAlreadyRegistered: false),
            .init(title: "洗濯", point: 20, isAlreadyRegistered: false),
            .init(title: "買い出し", point: 30, isAlreadyRegistered: false),
        ]

        // Act

        let actual = context.importCandidates(from: days)

        // Assert

        #expect(actual == expected)
    }

    @Test("同じ名前のいつもの家事がある候補は、登録済みとして返す")
    func alreadyRegisteredCandidateIsMarked() {
        // Arrange

        let updatedAt = Date.previewDate(year: 2026, month: 9, day: 1)
        let days: [HouseworkTemplateDay] = [
            .init(dayOfWeek: .monday, items: [
                .init(id: .init(id: "mon1"), title: "ゴミ出し", point: 10, updatedAt: updatedAt),
                .init(id: .init(id: "mon2"), title: "洗濯", point: 20, updatedAt: updatedAt),
            ]),
        ]
        let context = FrequentHouseworkContext(
            items: [.makeForTest(id: "1", title: "洗濯")],
            customCategories: []
        )
        let expected: [FrequentHouseworkImportCandidate] = [
            .init(title: "ゴミ出し", point: 10, isAlreadyRegistered: false),
            .init(title: "洗濯", point: 20, isAlreadyRegistered: true),
        ]

        // Act

        let actual = context.importCandidates(from: days)

        // Assert

        #expect(actual == expected)
    }

}
