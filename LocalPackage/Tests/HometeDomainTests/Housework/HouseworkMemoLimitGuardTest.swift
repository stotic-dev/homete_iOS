//
//  HouseworkMemoLimitGuardTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

/// メモの上限・編集可否を、ドメインモデルと保存処理で弾くことを検証する
/// - Note: 編集シートで保存できないようにしているが、Firestoreルールに当たる前にクライアントで弾く保険
enum HouseworkMemoLimitGuardTest {

    struct DomainCase {}
    @MainActor
    struct StoreCase {}

    /// 無料プランの上限（200文字）を超えるメモ
    static let overFreeLimitMemo = HouseworkMemo(text: String(repeating: "あ", count: 201), checklist: [])

}

extension HouseworkMemoLimitGuardTest.DomainCase {

    @Test("メモを持たない場合は、上限の検査を通る")
    func validate_nilMemo_passes() throws {
        // Act & Assert

        try HouseworkMemoLimitPolicy.free.validate(nil, original: nil)
    }

    @Test("上限を超えたメモはlimitExceededを返す")
    func validate_overLimit_throws() {
        // Act & Assert

        #expect(throws: HouseworkMemoError.limitExceeded) {
            try HouseworkMemoLimitPolicy.free.validate(HouseworkMemoLimitGuardTest.overFreeLimitMemo, original: nil)
        }
    }

    @Test("完了済みの家事のメモを更新しようとすると、notEditableを返す")
    func updateMemo_completed_throwsNotEditable() {
        // Arrange

        let item = HouseworkItem.makeForTest(id: 1, state: .completed, executorId: "userA")

        // Act & Assert

        #expect(throws: HouseworkMemoError.notEditable) {
            try item.updateMemo(.init(text: "メモ", checklist: []), limitPolicy: .free)
        }
    }

    @Test("家事のメモを上限を超えて更新しようとすると、limitExceededを返す")
    func updateMemo_overLimit_throwsLimitExceeded() {
        // Arrange

        let item = HouseworkItem.makeForTest(id: 1)

        // Act & Assert

        #expect(throws: HouseworkMemoError.limitExceeded) {
            try item.updateMemo(HouseworkMemoLimitGuardTest.overFreeLimitMemo, limitPolicy: .free)
        }
    }

    @Test("いつもの家事から選んだ家事のメモは、上限を超えていても検査しない")
    func newEntry_frequent_skipsValidation() throws {
        // Arrange

        let entry = NewHouseworkEntry(
            item: .makeForTest(id: 1, memo: HouseworkMemoLimitGuardTest.overFreeLimitMemo),
            source: .frequent
        )

        // Act & Assert

        try entry.validateMemo(limitPolicy: .free)
    }

    @Test("新しく入力した家事のメモが上限を超えていると、limitExceededを返す")
    func newEntry_manualOverLimit_throws() {
        // Arrange

        let entry = NewHouseworkEntry(
            item: .makeForTest(id: 1, memo: HouseworkMemoLimitGuardTest.overFreeLimitMemo),
            source: .manual
        )

        // Act & Assert

        #expect(throws: HouseworkMemoError.limitExceeded) {
            try entry.validateMemo(limitPolicy: .free)
        }
    }

    @Test("テンプレートの家事は、保存前より文字数が増えていなければ上限を超えていても検査を通る")
    func templateItem_notIncreased_passes() throws {
        // Arrange

        let original = HouseworkTemplateItem(
            id: .init(id: "1"),
            title: "買い出し",
            point: 10,
            updatedAt: .distantPast,
            memo: HouseworkMemoLimitGuardTest.overFreeLimitMemo
        )
        let edited = HouseworkTemplateItem(
            id: .init(id: "1"),
            title: "買い出し（週末）",
            point: 10,
            updatedAt: .distantPast,
            memo: HouseworkMemoLimitGuardTest.overFreeLimitMemo
        )

        // Act & Assert

        try edited.validateMemo(comparedTo: original, limitPolicy: .free)
    }

    @Test("いつもの家事の追加で、メモが上限を超えているとlimitExceededを返す")
    func frequentAdded_overLimit_throws() {
        // Arrange

        let context = FrequentHouseworkContext()

        // Act & Assert

        #expect(throws: HouseworkMemoError.limitExceeded) {
            try context.makeAddedItems(
                from: [.init(
                    title: "買い出し",
                    point: 10,
                    categoryId: nil,
                    memo: HouseworkMemoLimitGuardTest.overFreeLimitMemo
                )],
                limitPolicy: .premium,
                memoLimitPolicy: .free,
                timestamp: .distantPast,
                idGenerator: { "new" }
            )
        }
    }

}

extension HouseworkMemoLimitGuardTest.StoreCase {

    @Test("上限を超えたメモを保存しようとすると、書き込まずにlimitExceededを返す")
    func updateMemo_overLimit_doesNotWrite() async {
        // Arrange

        let item = HouseworkItem.makeForTest(id: 1)
        let store = HouseworkListStore(
            houseworkClient: .init(
                insertOrUpdateItemHandler: { _, _ in Issue.record() },
                updateMemoHandler: { _, _, _ in Issue.record() }
            ),
            items: [.makeForTest(items: [item])]
        )

        // Act & Assert

        await #expect(throws: HouseworkMemoError.limitExceeded) {
            try await store.updateMemo(
                target: item,
                memo: HouseworkMemoLimitGuardTest.overFreeLimitMemo,
                cohabitantId: "cohabitantId",
                isRegistered: true,
                step: .detail,
                limitPolicy: .free
            )
        }
    }

    @Test("上限を超えたメモを入力した家事があると、1件も登録せずにlimitExceededを返す")
    func register_overLimit_doesNotWrite() async {
        // Arrange

        let store = HouseworkListStore(houseworkClient: .init(insertItemsHandler: { _, _ in Issue.record() }))

        // Act & Assert

        await #expect(throws: HouseworkMemoError.limitExceeded) {
            try await store.register(
                newItems: [
                    .init(item: .makeForTest(id: 1), source: .manual),
                    .init(
                        item: .makeForTest(id: 2, memo: HouseworkMemoLimitGuardTest.overFreeLimitMemo),
                        source: .manual
                    ),
                ],
                cohabitantId: "cohabitantId",
                step: .board,
                memoLimitPolicy: .free
            )
        }
    }

    @Test("メモが上限を超えたテンプレートの家事があると、書き込まずにlimitExceededを返す")
    func saveTemplate_overLimit_doesNotWrite() async {
        // Arrange

        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(updateTemplate: { _, _, _, _ in Issue.record() })
        )
        let item = HouseworkTemplateItem(
            id: .init(id: "1"),
            title: "買い出し",
            point: 10,
            updatedAt: .distantPast,
            memo: HouseworkMemoLimitGuardTest.overFreeLimitMemo
        )

        // Act & Assert

        await #expect(throws: HouseworkMemoError.limitExceeded) {
            try await store.saveTemplate(
                days: [.init(dayOfWeek: .monday, items: [item])],
                monthlyItems: [],
                templateId: "templateId",
                cohabitantId: "cohabitantId",
                currentVersion: 0,
                memoLimitPolicy: .free
            )
        }
    }

    @Test("メモが上限を超えたいつもの家事を追加しようとすると、書き込まずにlimitExceededを返す")
    func addFrequent_overLimit_doesNotWrite() async {
        // Arrange

        let store = FrequentHouseworkStore(
            frequentHouseworkClient: .init(upsertItems: { _, _ in Issue.record() })
        )

        // Act & Assert

        await #expect(throws: HouseworkMemoError.limitExceeded) {
            try await store.add(
                [.init(title: "買い出し", point: 10, categoryId: nil, memo: HouseworkMemoLimitGuardTest.overFreeLimitMemo)],
                limitPolicy: .premium,
                memoLimitPolicy: .free,
                step: .management,
                cohabitantId: "cohabitantId"
            )
        }
    }

}
