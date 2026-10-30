//
//  HouseworkPostponePlanTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

enum HouseworkPostponePlanTest {

    struct SingleItemCase {}
    struct TemplateItemCase {}

    /// まわす前の日（2026/1/10 土曜日）
    static let sourceDate = Date.previewDate(year: 2026, month: 1, day: 10)
    /// まわす先の日（2026/1/11 日曜日）
    static let destinationDate = Date.previewDate(year: 2026, month: 1, day: 11)
    /// まわす先の日の保持期限（無料プランは1年）
    static let destinationExpiredAt = Date.previewDate(year: 2027, month: 1, day: 11)
    static let now = Date.previewDate(year: 2026, month: 1, day: 10, hour: 21)
    static let templateItemId = HouseworkTemplateItem.ItemId(id: "template1")
    /// 日曜日に出る、`templateItemId`のテンプレートの家事
    static let sundayTemplate = HouseworkTemplateContext(
        metadata: nil,
        houseworkTemplate: [
            .init(
                dayOfWeek: .sunday,
                items: [
                    .init(
                        id: templateItemId,
                        title: "お皿洗い",
                        point: 10,
                        updatedAt: .previewDate(year: 2026, month: 1, day: 1)
                    ),
                ]
            ),
        ]
    )

}

// MARK: - 単発の家事

extension HouseworkPostponePlanTest.SingleItemCase {

    @Test("単発の家事は、同じドキュメントの日付と保持期限を書き換え、まわす前の日付を付ける")
    func make_singleItem_movesSameDocument() {
        // Arrange
        let target = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkPostponePlanTest.sourceDate,
            title: "洗濯",
            expiredAt: .previewDate(year: 2027, month: 1, day: 10),
            createdAt: .previewDate(year: 2026, month: 1, day: 9),
            memo: .init(text: "柔軟剤を入れる", checklist: [])
        )
        let expected = HouseworkPostponePlan(
            writes: [
                .makeForTest(
                    id: "1",
                    indexedDate: HouseworkPostponePlanTest.destinationDate,
                    title: "洗濯",
                    expiredAt: HouseworkPostponePlanTest.destinationExpiredAt,
                    createdAt: .previewDate(year: 2026, month: 1, day: 9),
                    memo: .init(text: "柔軟剤を入れる", checklist: []),
                    postponedFrom: .init(value: HouseworkPostponePlanTest.sourceDate)
                ),
            ],
            outcome: .moved,
            conflictingTitle: nil
        )

        // Act
        let actual = HouseworkPostponePlan.make(
            target: target,
            isRegistered: true,
            destination: HouseworkPostponePlanTest.destinationDate,
            storedItems: .makeMultiDateList(items: [target]),
            templateContext: .init(metadata: nil, houseworkTemplate: []),
            now: HouseworkPostponePlanTest.now,
            calendar: .japanese,
            storagePolicy: .free,
            newItemId: "newId"
        )

        // Assert
        #expect(actual == expected)
    }

    @Test("まわす先に同じ名前の家事があれば、その名前を返す")
    func make_singleItemWithSameTitleOnDestination_returnsConflictingTitle() {
        // Arrange
        let target = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkPostponePlanTest.sourceDate,
            title: "洗濯",
            expiredAt: .previewDate(year: 2027, month: 1, day: 10)
        )
        let sameTitleItem = HouseworkItem.makeForTest(
            id: "2",
            indexedDate: HouseworkPostponePlanTest.destinationDate,
            title: "洗濯",
            state: .completed,
            executorId: "own"
        )
        let expected = HouseworkPostponePlan(
            writes: [
                .makeForTest(
                    id: "1",
                    indexedDate: HouseworkPostponePlanTest.destinationDate,
                    title: "洗濯",
                    expiredAt: HouseworkPostponePlanTest.destinationExpiredAt,
                    postponedFrom: .init(value: HouseworkPostponePlanTest.sourceDate)
                ),
            ],
            outcome: .moved,
            conflictingTitle: "洗濯"
        )

        // Act
        let actual = HouseworkPostponePlan.make(
            target: target,
            isRegistered: true,
            destination: HouseworkPostponePlanTest.destinationDate,
            storedItems: .makeMultiDateList(items: [target, sameTitleItem]),
            templateContext: .init(metadata: nil, houseworkTemplate: []),
            now: HouseworkPostponePlanTest.now,
            calendar: .japanese,
            storagePolicy: .free,
            newItemId: "newId"
        )

        // Assert
        #expect(actual == expected)
    }

}

// MARK: - テンプレートの家事

extension HouseworkPostponePlanTest.TemplateItemCase {

    @Test("まわす先に同じテンプレートの家事が未完了で出ていれば、元の日に記録を残すだけでまとめる")
    func make_templateItemWithIncompleteSameTemplateOnDestination_merges() {
        // Arrange
        let target = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkPostponePlanTest.sourceDate,
            title: "お皿洗い",
            point: 10,
            expiredAt: .previewDate(year: 2027, month: 1, day: 10),
            templateHouseworkItemId: HouseworkPostponePlanTest.templateItemId,
            createdAt: .previewDate(year: 2026, month: 1, day: 10)
        )
        let expected = HouseworkPostponePlan(
            writes: [
                .makeForTest(
                    id: "1",
                    indexedDate: HouseworkPostponePlanTest.sourceDate,
                    title: "お皿洗い",
                    point: 10,
                    state: .notTodo,
                    expiredAt: .previewDate(year: 2027, month: 1, day: 10),
                    templateHouseworkItemId: HouseworkPostponePlanTest.templateItemId,
                    createdAt: .previewDate(year: 2026, month: 1, day: 10),
                    postponedTo: .init(value: HouseworkPostponePlanTest.destinationDate)
                ),
            ],
            outcome: .merged,
            conflictingTitle: nil
        )

        // Act
        let actual = HouseworkPostponePlan.make(
            target: target,
            isRegistered: true,
            destination: HouseworkPostponePlanTest.destinationDate,
            storedItems: .makeMultiDateList(items: [target]),
            templateContext: HouseworkPostponePlanTest.sundayTemplate,
            now: HouseworkPostponePlanTest.now,
            calendar: .japanese,
            storagePolicy: .free,
            newItemId: "newId"
        )

        // Assert
        #expect(actual == expected)
    }

    @Test("まわす先の同じテンプレートの家事が完了していれば、まとめずに単発の家事として移す")
    func make_templateItemWithCompletedSameTemplateOnDestination_movesAsSingleItem() {
        // Arrange
        let target = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkPostponePlanTest.sourceDate,
            title: "お皿洗い",
            point: 10,
            expiredAt: .previewDate(year: 2027, month: 1, day: 10),
            templateHouseworkItemId: HouseworkPostponePlanTest.templateItemId,
            createdAt: .previewDate(year: 2026, month: 1, day: 10)
        )
        let completedOnDestination = HouseworkItem.makeForTest(
            id: "2",
            indexedDate: HouseworkPostponePlanTest.destinationDate,
            title: "お皿洗い",
            point: 10,
            state: .completed,
            executorId: "own",
            templateHouseworkItemId: HouseworkPostponePlanTest.templateItemId
        )
        let expected = HouseworkPostponePlan(
            writes: [
                .makeForTest(
                    id: "1",
                    indexedDate: HouseworkPostponePlanTest.sourceDate,
                    title: "お皿洗い",
                    point: 10,
                    state: .notTodo,
                    expiredAt: .previewDate(year: 2027, month: 1, day: 10),
                    templateHouseworkItemId: HouseworkPostponePlanTest.templateItemId,
                    createdAt: .previewDate(year: 2026, month: 1, day: 10),
                    postponedTo: .init(value: HouseworkPostponePlanTest.destinationDate)
                ),
                .makeForTest(
                    id: "newId",
                    indexedDate: HouseworkPostponePlanTest.destinationDate,
                    title: "お皿洗い",
                    point: 10,
                    expiredAt: HouseworkPostponePlanTest.destinationExpiredAt,
                    createdAt: HouseworkPostponePlanTest.now,
                    postponedFrom: .init(value: HouseworkPostponePlanTest.sourceDate)
                ),
            ],
            outcome: .moved,
            conflictingTitle: "お皿洗い"
        )

        // Act
        let actual = HouseworkPostponePlan.make(
            target: target,
            isRegistered: true,
            destination: HouseworkPostponePlanTest.destinationDate,
            storedItems: .makeMultiDateList(items: [target, completedOnDestination]),
            templateContext: HouseworkPostponePlanTest.sundayTemplate,
            now: HouseworkPostponePlanTest.now,
            calendar: .japanese,
            storagePolicy: .free,
            newItemId: "newId"
        )

        // Assert
        #expect(actual == expected)
    }

    @Test("未登録のテンプレートの家事を、同じテンプレートの家事が出ない日へまわすと、元の日の記録を新しく作り、まわす先に単発の家事を作る")
    func make_unregisteredTemplateItemToDayWithoutTemplate_createsRecordAndCopy() {
        // Arrange
        let target = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: HouseworkPostponePlanTest.sourceDate,
            title: "お皿洗い",
            point: 10,
            expiredAt: .previewDate(year: 2027, month: 1, day: 10),
            templateHouseworkItemId: HouseworkPostponePlanTest.templateItemId,
            memo: .init(text: "", checklist: [.init(id: "c1", title: "鍋", isChecked: false)])
        )
        let expected = HouseworkPostponePlan(
            writes: [
                .makeForTest(
                    id: "1",
                    indexedDate: HouseworkPostponePlanTest.sourceDate,
                    title: "お皿洗い",
                    point: 10,
                    state: .notTodo,
                    expiredAt: .previewDate(year: 2027, month: 1, day: 10),
                    templateHouseworkItemId: HouseworkPostponePlanTest.templateItemId,
                    createdAt: HouseworkPostponePlanTest.now,
                    memo: .init(text: "", checklist: [.init(id: "c1", title: "鍋", isChecked: false)]),
                    postponedTo: .init(value: HouseworkPostponePlanTest.destinationDate)
                ),
                .makeForTest(
                    id: "newId",
                    indexedDate: HouseworkPostponePlanTest.destinationDate,
                    title: "お皿洗い",
                    point: 10,
                    expiredAt: HouseworkPostponePlanTest.destinationExpiredAt,
                    createdAt: HouseworkPostponePlanTest.now,
                    memo: .init(text: "", checklist: [.init(id: "c1", title: "鍋", isChecked: false)]),
                    postponedFrom: .init(value: HouseworkPostponePlanTest.sourceDate)
                ),
            ],
            outcome: .moved,
            conflictingTitle: nil
        )

        // Act
        let actual = HouseworkPostponePlan.make(
            target: target,
            isRegistered: false,
            destination: HouseworkPostponePlanTest.destinationDate,
            storedItems: .makeMultiDateList(items: []),
            templateContext: .init(metadata: nil, houseworkTemplate: []),
            now: HouseworkPostponePlanTest.now,
            calendar: .japanese,
            storagePolicy: .free,
            newItemId: "newId"
        )

        // Assert
        #expect(actual == expected)
    }

}
