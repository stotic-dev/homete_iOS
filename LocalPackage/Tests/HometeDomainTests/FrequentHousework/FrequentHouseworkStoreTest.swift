//
//  FrequentHouseworkStoreTest.swift
//  LocalPackage
//

// swiftlint:disable file_length

import Foundation
@testable import HometeDomain
import Testing

enum FrequentHouseworkStoreTest {

    struct ObservingCase {}
    struct AddCase {}
    struct ImportCase {}
    struct UpdateCase {}
    struct DeleteAndReorderCase {}
    struct CategoryCase {}

    static let inputCohabitantId = "cohabitantId"
    static let fixedNow = Date.previewDate(year: 2026, month: 9, day: 26)

}

// MARK: - 購読

extension FrequentHouseworkStoreTest.ObservingCase {

    @MainActor
    @Test("いつもの家事とカテゴリの最初のスナップショットが揃うと、両方を反映して読み込み済みになる")
    func startObservingReflectsItemsAndCategories() async {
        // Arrange

        let expectedItems: [FrequentHouseworkItem] = [.makeForTest(id: "1")]
        let expectedCategories: [FrequentHouseworkCustomCategory] = [.makeForTest(id: "pet")]
        let (itemsStream, itemsContinuation) = AsyncStream<[FrequentHouseworkItem]>.makeStream()
        let (categoriesStream, categoriesContinuation) = AsyncStream<[FrequentHouseworkCustomCategory]>.makeStream()
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(
                addItemsSnapshotListener: { _, cohabitantId in
                    #expect(cohabitantId == FrequentHouseworkStoreTest.inputCohabitantId)
                    return itemsStream
                },
                addCategoriesSnapshotListener: { _, _ in categoriesStream }
            )
        )

        // Act

        await store.startObserving(cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId)

        // Assert

        let waiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.loadState
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        categoriesContinuation.yield(expectedCategories)
        itemsContinuation.yield(expectedItems)
        await waiter.value
        #expect(store.items == expectedItems)
        #expect(store.customCategories == expectedCategories)
        #expect(store.loadState == .loaded)

        // Cleanup

        itemsContinuation.finish()
        categoriesContinuation.finish()
        await store.stopObserving()
    }

    @MainActor
    @Test("いつもの家事だけが届いてカテゴリがまだ届いていない間は、読み込み中のまま")
    func startObservingStaysLoadingUntilCategoriesArrive() async {
        // Arrange

        let (itemsStream, itemsContinuation) = AsyncStream<[FrequentHouseworkItem]>.makeStream()
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(
                addItemsSnapshotListener: { _, _ in itemsStream }
            )
        )

        // Act

        await store.startObserving(cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId)

        // Assert

        let waiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.items
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        itemsContinuation.yield([.makeForTest(id: "1")])
        await waiter.value
        #expect(store.loadState == .loading)

        // Cleanup

        await store.stopObserving()
        itemsContinuation.finish()
    }

    @MainActor
    @Test("最初のスナップショットが揃う前にリスナーが終わると、読み込みに失敗した状態になる")
    func startObservingFailsWhenListenerEndsBeforeLoaded() async {
        // Arrange

        let (itemsStream, itemsContinuation) = AsyncStream<[FrequentHouseworkItem]>.makeStream()
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(
                addItemsSnapshotListener: { _, _ in itemsStream }
            )
        )

        // Act

        await store.startObserving(cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId)

        // Assert

        let waiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.loadState
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        itemsContinuation.finish()
        await waiter.value
        #expect(store.loadState == .failed(.other))

        // Cleanup

        await store.stopObserving()
    }

    @MainActor
    @Test("片方のリスナーが先に終わって失敗になった後は、もう片方が届いても失敗のままにする")
    func startObservingStaysFailedAfterOneListenerEnds() async {
        // Arrange

        let (itemsStream, itemsContinuation) = AsyncStream<[FrequentHouseworkItem]>.makeStream()
        let (categoriesStream, categoriesContinuation) = AsyncStream<[FrequentHouseworkCustomCategory]>.makeStream()
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(
                addItemsSnapshotListener: { _, _ in itemsStream },
                addCategoriesSnapshotListener: { _, _ in categoriesStream }
            )
        )
        await store.startObserving(cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId)
        let failedWaiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.loadState
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        itemsContinuation.yield([.makeForTest(id: "1")])
        itemsContinuation.finish()
        await failedWaiter.value

        // Act

        let categoriesWaiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.customCategories
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        categoriesContinuation.yield([.makeForTest(id: "pet")])
        await categoriesWaiter.value

        // Assert

        #expect(store.loadState == .failed(.other))

        // Cleanup

        await store.stopObserving()
        categoriesContinuation.finish()
    }

    @MainActor
    @Test("購読を開始すると、受け取ったカスタムカテゴリを反映する")
    func startObservingReflectsCategories() async {
        // Arrange

        let expectedCategories: [FrequentHouseworkCustomCategory] = [.makeForTest(id: "pet")]
        let (categoriesStream, categoriesContinuation) = AsyncStream<[FrequentHouseworkCustomCategory]>.makeStream()
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(
                addCategoriesSnapshotListener: { _, _ in categoriesStream }
            )
        )

        // Act

        await store.startObserving(cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId)

        // Assert

        let waiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.customCategories
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        categoriesContinuation.yield(expectedCategories)
        await waiter.value
        #expect(store.customCategories == expectedCategories)

        // Cleanup

        categoriesContinuation.finish()
        await store.stopObserving()
    }

    @MainActor
    @Test("購読を解除すると、いつもの家事とカスタムカテゴリの両方のリスナーを解除する")
    func stopObservingRemovesBothListeners() async {
        // Arrange

        let removedListenerKeys = TestLockedArray<String>()
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(
                removeListener: { id in await removedListenerKeys.append(id) }
            )
        )

        // Act

        await store.stopObserving()

        // Assert

        let actual = await removedListenerKeys.values
        #expect(actual == ["frequentHouseworksListener", "frequentHouseworkCategoriesListener"])
    }

}

// MARK: - 追加

extension FrequentHouseworkStoreTest.AddCase {

    @MainActor
    @Test("追加すると、名前の前後の空白を除き、各カテゴリの末尾の並び順で書き込む")
    func addWritesItemsAtEndOfEachCategory() async throws {
        // Arrange

        let existing = FrequentHouseworkItem.makeForTest(id: "existing", categoryId: "preset.cleaning", sortOrder: 2)
        let generatedIds = TestBox(value: ["new1", "new2", "new3"])
        let now = FrequentHouseworkStoreTest.fixedNow
        let expectedItems: [FrequentHouseworkItem] = [
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

        try await confirmation { confirmation in
            let store = FrequentHouseworkStore(
                frequentHouseworkClient: .init(
                    upsertItems: { items, cohabitantId in
                        // Assert

                        #expect(items == expectedItems)
                        #expect(cohabitantId == FrequentHouseworkStoreTest.inputCohabitantId)
                        confirmation()
                    }
                ),
                items: [existing],
                now: { now },
                idGenerator: { generatedIds.value.removeFirst() }
            )

            // Act

            try await store.add(
                [
                    .init(title: " 風呂掃除 ", point: 20, categoryId: "preset.cleaning"),
                    .init(title: "窓拭き", point: 30, categoryId: "preset.cleaning"),
                    .init(title: "買い出し", point: 10, categoryId: nil),
                ],
                limitPolicy: .premium,
                step: .management,
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }
    }

    @MainActor
    @Test("追加に成功すると、家事1件につき1つcreateイベントを送る")
    func addLogsCreatePerItem() async throws {
        // Arrange

        let loggedEvents = TestBox<[AnalyticsEvent]>(value: [])
        let store = FrequentHouseworkStore(
            analyticsClient: .init(log: { event in loggedEvents.value.append(event) })
        )
        let expected: [AnalyticsEvent] = [
            .frequentHousework(.create(step: .register, isSuccess: true)),
            .frequentHousework(.create(step: .register, isSuccess: true)),
        ]

        // Act

        try await store.add(
            [
                .init(title: "風呂掃除", point: 10, categoryId: nil),
                .init(title: "窓拭き", point: 10, categoryId: nil),
            ],
            limitPolicy: .premium,
            step: .register,
            cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
        )

        // Assert

        #expect(loggedEvents.value == expected)
    }

    @MainActor
    @Test("書き込みに失敗すると、家事1件につき1つ失敗のcreateイベントを送ってエラーを返す")
    func addFailureLogsFailurePerItem() async {
        // Arrange

        let loggedEvents = TestBox<[AnalyticsEvent]>(value: [])
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(upsertItems: { _, _ in throw DomainError.noNetwork }),
            analyticsClient: .init(log: { event in loggedEvents.value.append(event) })
        )
        let expected: [AnalyticsEvent] = [
            .frequentHousework(.create(step: .template, isSuccess: false)),
        ]

        // Act

        await #expect(throws: DomainError.noNetwork) {
            try await store.add(
                [.init(title: "風呂掃除", point: 10, categoryId: nil)],
                limitPolicy: .premium,
                step: .template,
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }

        // Assert

        #expect(loggedEvents.value == expected)
    }

    @MainActor
    @Test(
        "名前が空・既存と重複・入力同士で重複している場合は、書き込まずにエラーを返す",
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
    func addInvalidInputThrows(inputs: [FrequentHouseworkInput], expectedError: FrequentHouseworkError) async {
        // Arrange

        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(upsertItems: { _, _ in Issue.record() }),
            items: [.makeForTest(id: "1", title: "洗濯")]
        )

        // Act & Assert

        await #expect(throws: expectedError) {
            try await store.add(
                inputs,
                limitPolicy: .premium,
                step: .management,
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }
    }

    @MainActor
    @Test("無料プランで上限を超える場合は、書き込まずにlimitExceededを返す")
    func addOverLimitThrows() async {
        // Arrange

        let existingItems = (0 ..< 9).map { FrequentHouseworkItem.makeForTest(id: "\($0)", sortOrder: $0) }
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(upsertItems: { _, _ in Issue.record() }),
            items: existingItems
        )

        // Act & Assert

        await #expect(throws: FrequentHouseworkError.limitExceeded) {
            try await store.add(
                [
                    .init(title: "風呂掃除", point: 10, categoryId: nil),
                    .init(title: "窓拭き", point: 10, categoryId: nil),
                ],
                limitPolicy: .free,
                step: .management,
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }
    }

}

// MARK: - 取り込み

extension FrequentHouseworkStoreTest.ImportCase {

    @MainActor
    @Test("テンプレートから取り込むと、登録済みの候補を除き、カテゴリ未設定で書き込む")
    func importWritesUnregisteredCandidatesAsUncategorized() async throws {
        // Arrange

        let now = FrequentHouseworkStoreTest.fixedNow
        let expectedItems: [FrequentHouseworkItem] = [
            .init(id: "new", title: "ゴミ出し", point: 10, categoryId: nil, sortOrder: 1, createdAt: now, updatedAt: now),
        ]

        try await confirmation { confirmation in
            let store = FrequentHouseworkStore(
                frequentHouseworkClient: .init(
                    upsertItems: { items, _ in
                        // Assert

                        #expect(items == expectedItems)
                        confirmation()
                    }
                ),
                items: [.makeForTest(id: "1", title: "洗濯", sortOrder: 0)],
                now: { now },
                idGenerator: { "new" }
            )

            // Act

            try await store.importFromTemplate(
                [
                    .init(title: "ゴミ出し", point: 10, isAlreadyRegistered: false),
                    .init(title: "洗濯", point: 20, isAlreadyRegistered: true),
                ],
                limitPolicy: .free,
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }
    }

    @MainActor
    @Test("取り込みに成功すると、件数に関係なくimportイベントを1つ送る")
    func importLogsOnce() async throws {
        // Arrange

        let loggedEvents = TestBox<[AnalyticsEvent]>(value: [])
        let store = FrequentHouseworkStore(
            analyticsClient: .init(log: { event in loggedEvents.value.append(event) })
        )
        let expected: [AnalyticsEvent] = [.frequentHousework(.importFromTemplate(isSuccess: true))]

        // Act

        try await store.importFromTemplate(
            [
                .init(title: "ゴミ出し", point: 10, isAlreadyRegistered: false),
                .init(title: "洗濯", point: 20, isAlreadyRegistered: false),
            ],
            limitPolicy: .premium,
            cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
        )

        // Assert

        #expect(loggedEvents.value == expected)
    }

}

// MARK: - 編集

extension FrequentHouseworkStoreTest.UpdateCase {

    @MainActor
    @Test("カテゴリを変えずに編集すると、並び順と作成日時を保ったまま内容と更新日時を書き込む")
    func updateInSameCategoryKeepsSortOrder() async throws {
        // Arrange

        let now = FrequentHouseworkStoreTest.fixedNow
        let current = FrequentHouseworkItem.makeForTest(
            id: "1",
            title: "風呂",
            point: 10,
            categoryId: "preset.cleaning",
            sortOrder: 3
        )
        let expectedItem = FrequentHouseworkItem(
            id: "1",
            title: "風呂掃除",
            point: 20,
            categoryId: "preset.cleaning",
            sortOrder: 3,
            createdAt: current.createdAt,
            updatedAt: now
        )

        try await confirmation { confirmation in
            let store = FrequentHouseworkStore(
                frequentHouseworkClient: .init(
                    upsertItems: { items, _ in
                        // Assert

                        #expect(items == [expectedItem])
                        confirmation()
                    }
                ),
                items: [current],
                now: { now }
            )

            // Act

            try await store.update(
                itemId: "1",
                input: .init(title: "風呂掃除", point: 20, categoryId: "preset.cleaning"),
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }
    }

    @MainActor
    @Test("カテゴリを変えて編集すると、移動先のカテゴリの末尾に並べる")
    func updateToOtherCategoryMovesToEnd() async throws {
        // Arrange

        let now = FrequentHouseworkStoreTest.fixedNow
        let current = FrequentHouseworkItem.makeForTest(id: "1", title: "布団干し", categoryId: nil, sortOrder: 0)
        let laundry = FrequentHouseworkItem.makeForTest(
            id: "2",
            title: "洗濯",
            categoryId: "preset.laundry",
            sortOrder: 4
        )
        let expectedItem = FrequentHouseworkItem(
            id: "1",
            title: "布団干し",
            point: 10,
            categoryId: "preset.laundry",
            sortOrder: 5,
            createdAt: current.createdAt,
            updatedAt: now
        )

        try await confirmation { confirmation in
            let store = FrequentHouseworkStore(
                frequentHouseworkClient: .init(
                    upsertItems: { items, _ in
                        // Assert

                        #expect(items == [expectedItem])
                        confirmation()
                    }
                ),
                items: [current, laundry],
                now: { now }
            )

            // Act

            try await store.update(
                itemId: "1",
                input: .init(title: "布団干し", point: 10, categoryId: "preset.laundry"),
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }
    }

    @MainActor
    @Test("ほかの家事と同じ名前に編集しようとすると、書き込まずにduplicatedTitleを返す")
    func updateToDuplicatedTitleThrows() async {
        // Arrange

        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(upsertItems: { _, _ in Issue.record() }),
            items: [
                .makeForTest(id: "1", title: "風呂"),
                .makeForTest(id: "2", title: "洗濯"),
            ]
        )

        // Act & Assert

        await #expect(throws: FrequentHouseworkError.duplicatedTitle) {
            try await store.update(
                itemId: "1",
                input: .init(title: "洗濯", point: 10, categoryId: nil),
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }
    }

    @MainActor
    @Test("編集中に家事が削除されていた場合は、復活させないよう書き込まない")
    func updateDeletedItemDoesNothing() async throws {
        // Arrange

        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(upsertItems: { _, _ in Issue.record() }),
            items: []
        )

        // Act & Assert

        try await store.update(
            itemId: "deleted",
            input: .init(title: "風呂", point: 10, categoryId: nil),
            cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
        )
    }

}

// MARK: - 削除・並べ替え

extension FrequentHouseworkStoreTest.DeleteAndReorderCase {

    @MainActor
    @Test("削除すると、指定した家事を削除してdeleteイベントを送る")
    func deleteRemovesItemAndLogs() async throws {
        // Arrange

        let loggedEvents = TestBox<[AnalyticsEvent]>(value: [])
        let deletedIds = TestLockedArray<String>()
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(deleteItem: { id, _ in await deletedIds.append(id) }),
            analyticsClient: .init(log: { event in loggedEvents.value.append(event) })
        )

        // Act

        try await store.delete(itemId: "1", cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId)

        // Assert

        let actualDeletedIds = await deletedIds.values
        #expect(actualDeletedIds == ["1"])
        #expect(loggedEvents.value == [.frequentHousework(.delete(isSuccess: true))])
    }

    @MainActor
    @Test("並べ替えると、並び順が変わった家事だけを新しい並び順で書き込む")
    func reorderWritesOnlyChangedItems() async throws {
        // Arrange

        let first = FrequentHouseworkItem.makeForTest(id: "1", sortOrder: 0)
        let second = FrequentHouseworkItem.makeForTest(id: "2", sortOrder: 1)
        let third = FrequentHouseworkItem.makeForTest(id: "3", sortOrder: 2)
        let expectedItems: [FrequentHouseworkItem] = [
            .makeForTest(id: "3", sortOrder: 1),
            .makeForTest(id: "2", sortOrder: 2),
        ]

        try await confirmation { confirmation in
            let store = FrequentHouseworkStore(
                frequentHouseworkClient: .init(
                    upsertItems: { items, _ in
                        // Assert

                        #expect(items == expectedItems)
                        confirmation()
                    }
                ),
                items: [first, second, third]
            )

            // Act

            try await store.reorderItems(["1", "3", "2"], cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId)
        }
    }

}

// MARK: - カスタムカテゴリ

extension FrequentHouseworkStoreTest.CategoryCase {

    @MainActor
    @Test("カテゴリを追加すると、カスタムカテゴリの末尾の並び順で書き込み、追加したカテゴリを返す")
    func addCategoryWritesAtEnd() async throws {
        // Arrange

        let now = FrequentHouseworkStoreTest.fixedNow
        let upsertedCategories = TestBox<[FrequentHouseworkCustomCategory]>(value: [])
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(
                upsertCategories: { categories, _ in upsertedCategories.value = categories }
            ),
            customCategories: [.makeForTest(id: "pet", name: "ペット", sortOrder: 2)],
            now: { now },
            idGenerator: { "new" }
        )
        let expected = FrequentHouseworkCustomCategory(id: "new", name: "子ども", sortOrder: 3, createdAt: now)

        // Act

        let actual = try await store.addCategory(
            name: " 子ども ",
            cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
        )

        // Assert

        #expect(actual == expected)
        #expect(upsertedCategories.value == [expected])
    }

    @MainActor
    @Test(
        "カテゴリ名が空・プリセットや「その他」・既存のカスタムと重複する場合は、書き込まずにエラーを返す",
        arguments: [
            (" ", FrequentHouseworkError.emptyCategoryName),
            ("洗濯", FrequentHouseworkError.duplicatedCategoryName),
            ("その他", FrequentHouseworkError.duplicatedCategoryName),
            ("ペット", FrequentHouseworkError.duplicatedCategoryName),
        ]
    )
    func addInvalidCategoryThrows(name: String, expectedError: FrequentHouseworkError) async {
        // Arrange

        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(upsertCategories: { _, _ in Issue.record() }),
            customCategories: [.makeForTest(id: "pet", name: "ペット")]
        )

        // Act & Assert

        await #expect(throws: expectedError) {
            try await store.addCategory(name: name, cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId)
        }
    }

    @MainActor
    @Test("カテゴリ名を変更すると、並び順と作成日時を保ったまま名前を書き込む")
    func renameCategoryKeepsOrder() async throws {
        // Arrange

        let current = FrequentHouseworkCustomCategory.makeForTest(id: "pet", name: "ペット", sortOrder: 1)
        let expected = FrequentHouseworkCustomCategory(
            id: "pet",
            name: "ペットのお世話",
            sortOrder: 1,
            createdAt: current.createdAt
        )

        try await confirmation { confirmation in
            let store = FrequentHouseworkStore(
                frequentHouseworkClient: .init(
                    upsertCategories: { categories, _ in
                        // Assert

                        #expect(categories == [expected])
                        confirmation()
                    }
                ),
                customCategories: [current]
            )

            // Act

            try await store.renameCategory(
                id: "pet",
                name: "ペットのお世話",
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }
    }

    @MainActor
    @Test("カテゴリを削除すると、カテゴリだけを削除してdelete_categoryイベントを送る")
    func deleteCategoryRemovesOnlyCategory() async throws {
        // Arrange

        let loggedEvents = TestBox<[AnalyticsEvent]>(value: [])
        let deletedIds = TestLockedArray<String>()
        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(
                upsertItems: { _, _ in Issue.record() },
                deleteItem: { _, _ in Issue.record() },
                deleteCategory: { id, _ in await deletedIds.append(id) }
            ),
            analyticsClient: .init(log: { event in loggedEvents.value.append(event) }),
            items: [.makeForTest(id: "1", categoryId: "pet")],
            customCategories: [.makeForTest(id: "pet")]
        )

        // Act

        try await store.deleteCategory(id: "pet", cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId)

        // Assert

        let actualDeletedIds = await deletedIds.values
        #expect(actualDeletedIds == ["pet"])
        #expect(loggedEvents.value == [.frequentHousework(.deleteCategory(isSuccess: true))])
    }

    @MainActor
    @Test("カテゴリを並べ替えると、並び順が変わったカテゴリだけを新しい並び順で書き込む")
    func reorderCategoriesWritesOnlyChanged() async throws {
        // Arrange

        let expected: [FrequentHouseworkCustomCategory] = [
            .makeForTest(id: "b", sortOrder: 0),
            .makeForTest(id: "a", sortOrder: 1),
        ]

        try await confirmation { confirmation in
            let store = FrequentHouseworkStore(
                frequentHouseworkClient: .init(
                    upsertCategories: { categories, _ in
                        // Assert

                        #expect(categories == expected)
                        confirmation()
                    }
                ),
                customCategories: [
                    .makeForTest(id: "a", sortOrder: 0),
                    .makeForTest(id: "b", sortOrder: 1),
                    .makeForTest(id: "c", sortOrder: 2),
                ]
            )

            // Act

            try await store.reorderCategories(
                ["b", "a", "c"],
                cohabitantId: FrequentHouseworkStoreTest.inputCohabitantId
            )
        }
    }

}
