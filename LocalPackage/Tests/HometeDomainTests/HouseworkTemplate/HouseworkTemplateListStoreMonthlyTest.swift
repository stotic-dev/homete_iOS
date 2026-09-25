//
//  HouseworkTemplateListStoreMonthlyTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkTemplateListStoreMonthlyTest {

    private nonisolated static let inputCohabitantId = "cohabitantId"
    private nonisolated static let inputTemplateId = "templateId"

    private static let rent = HouseworkTemplateMonthlyItem(
        item: .init(id: .init(id: "rent"), title: "家賃の振込", point: 5, updatedAt: .distantPast),
        rule: .dayOfMonth(25)
    )
    private static let recycling = HouseworkTemplateMonthlyItem(
        item: .init(id: .init(id: "recycling"), title: "資源ゴミ", point: 3, updatedAt: .distantPast),
        rule: .dayOfMonth(10)
    )

    @Test("saveTemplateで毎月の家事を渡すと、現在の内容との差分だけを書き込み、monthlyItemsを置き換える")
    func saveTemplateWritesMonthlyItemsDiff() async throws {
        // Arrange

        let editedRent = HouseworkTemplateMonthlyItem(
            item: .init(id: .init(id: "rent"), title: "家賃の振込", point: 5, updatedAt: .distantPast),
            rule: .dayOfMonth(27)
        )
        let newItem = HouseworkTemplateMonthlyItem(
            item: .init(id: .init(id: "new"), title: "排水口の掃除", point: 8, updatedAt: .distantPast),
            rule: .dayOfMonth(1)
        )
        let inputMonthlyItems = [Self.recycling, editedRent, newItem]
        let expectedUpdate = HouseworkTemplateUpdate(
            upsertedMonthlyItems: [editedRent, newItem],
            deletedMonthlyItemIds: []
        )

        try await confirmation { confirmation in
            let store = HouseworkTemplateListStore(
                houseworkTemplateClient: .init(
                    updateTemplate: { update, _, _, _ in
                        #expect(update == expectedUpdate)
                        confirmation()
                    }
                ),
                monthlyItems: [Self.rent, Self.recycling]
            )

            // Act

            try await store.saveTemplate(
                days: [],
                monthlyItems: inputMonthlyItems,
                templateId: Self.inputTemplateId,
                cohabitantId: Self.inputCohabitantId,
                currentVersion: 0
            )

            // Assert

            #expect(store.monthlyItems == inputMonthlyItems)
        }
    }

    @Test("saveTemplateで毎月の家事を取り除くと、削除するIDとして書き込む")
    func saveTemplateDeletesRemovedMonthlyItems() async throws {
        // Arrange

        let expectedUpdate = HouseworkTemplateUpdate(deletedMonthlyItemIds: [Self.rent.id])

        try await confirmation { confirmation in
            let store = HouseworkTemplateListStore(
                houseworkTemplateClient: .init(
                    updateTemplate: { update, _, _, _ in
                        #expect(update == expectedUpdate)
                        confirmation()
                    }
                ),
                monthlyItems: [Self.rent, Self.recycling]
            )

            // Act

            try await store.saveTemplate(
                days: [],
                monthlyItems: [Self.recycling],
                templateId: Self.inputTemplateId,
                cohabitantId: Self.inputCohabitantId,
                currentVersion: 0
            )
        }
    }

    @Test("saveTemplateで毎月の家事に変更がなくDaysも空なら、updateTemplateは呼ばれない")
    func saveTemplateWithoutMonthlyChangesIsNoop() async throws {
        // Arrange

        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                updateTemplate: { _, _, _, _ in Issue.record() }
            ),
            monthlyItems: [Self.rent]
        )

        // Act

        try await store.saveTemplate(
            days: [],
            monthlyItems: [Self.rent],
            templateId: Self.inputTemplateId,
            cohabitantId: Self.inputCohabitantId,
            currentVersion: 0
        )

        // Assert

        #expect(store.monthlyItems == [Self.rent])
    }

    @Test("configureを呼ぶと、先頭テンプレートの毎月の家事を取得してmonthlyItemsに反映する")
    func configureLoadsMonthlyItems() async throws {
        // Arrange

        let expectedMonthlyItems = [Self.rent, Self.recycling]
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                fetchTemplates: { _ in [.init(templateId: Self.inputTemplateId, name: "default")] },
                fetchMonthlyItems: { cohabitantId, templateId in
                    #expect(cohabitantId == Self.inputCohabitantId)
                    #expect(templateId == Self.inputTemplateId)
                    return expectedMonthlyItems
                }
            )
        )

        // Act

        try await store.configure(cohabitantId: Self.inputCohabitantId)

        // Assert

        #expect(store.monthlyItems == expectedMonthlyItems)

        // Cleanup

        await store.stopObservingItems()
    }

    @Test("毎週の家事を同じIDのまま毎月に変えて保存すると、追加・削除ではなく編集としてイベントを送る")
    func saveTemplateLogsEditWhenRecurrenceChanged() async throws {
        // Arrange

        let item = HouseworkTemplateItem(id: .init(id: "item"), title: "掃除", point: 5, updatedAt: .distantPast)

        try await confirmation { confirmation in
            let store = HouseworkTemplateListStore(
                analyticsClient: .init(log: { event in
                    #expect(event == .houseworkTemplate(.edit(isSuccess: true, recurrence: .monthly(.dayOfMonth(1)))))
                    confirmation()
                }),
                selectedDays: [.init(dayOfWeek: .monday, items: [item])]
            )

            // Act

            try await store.saveTemplate(
                days: [.init(dayOfWeek: .monday, items: [])],
                monthlyItems: [.init(item: item, rule: .dayOfMonth(1))],
                templateId: Self.inputTemplateId,
                cohabitantId: Self.inputCohabitantId,
                currentVersion: 0
            )
        }
    }

}

extension HouseworkTemplateListStoreMonthlyTest {

    @Test("appendItemを呼ぶと、Clientに家事と繰り返し方を渡し、追加成功のイベントを送る")
    func appendItemSucceeds() async throws {
        // Arrange

        let inputItem = HouseworkTemplateItem(id: .init(id: "item"), title: "掃除", point: 5, updatedAt: .distantPast)
        let inputRecurrence = HouseworkRecurrence.weekly([.monday, .thursday])

        try await confirmation(expectedCount: 2) { confirmation in
            let store = HouseworkTemplateListStore(
                houseworkTemplateClient: .init(
                    appendItem: { item, recurrence, templateId, cohabitantId in
                        #expect(item == inputItem)
                        #expect(recurrence == inputRecurrence)
                        #expect(templateId == Self.inputTemplateId)
                        #expect(cohabitantId == Self.inputCohabitantId)
                        confirmation()
                    }
                ),
                analyticsClient: .init(log: { event in
                    #expect(event == .houseworkTemplate(.create(
                        isSuccess: true,
                        step: .register,
                        recurrence: inputRecurrence
                    )))
                    confirmation()
                })
            )

            // Act

            try await store.appendItem(
                inputItem,
                recurrence: inputRecurrence,
                templateId: Self.inputTemplateId,
                cohabitantId: Self.inputCohabitantId
            )
        }
    }

    @Test("appendItemに失敗すると、エラーをthrowし追加失敗のイベントを送る")
    func appendItemFails() async {
        // Arrange

        let inputItem = HouseworkTemplateItem(id: .init(id: "item"), title: "掃除", point: 5, updatedAt: .distantPast)

        await confirmation { confirmation in
            let store = HouseworkTemplateListStore(
                houseworkTemplateClient: .init(
                    appendItem: { _, _, _, _ in throw DomainError.noNetwork }
                ),
                analyticsClient: .init(log: { event in
                    let expected = AnalyticsEvent.houseworkTemplate(
                        .create(isSuccess: false, step: .register, recurrence: .monthly(.dayOfMonth(25)))
                    )
                    #expect(event == expected)
                    confirmation()
                })
            )

            // Act + Assert

            await #expect(throws: DomainError.noNetwork) {
                try await store.appendItem(
                    inputItem,
                    recurrence: .monthly(.dayOfMonth(25)),
                    templateId: Self.inputTemplateId,
                    cohabitantId: Self.inputCohabitantId
                )
            }
        }
    }

    @Test("configureで毎月の家事の取得だけに失敗しても、毎週の家事は読み込み済みとして扱う")
    func configureSucceedsWhenMonthlyItemsFetchFails() async throws {
        // Arrange

        let expectedDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: .monday,
                items: [.init(id: .init(id: "id"), title: "ゴミ出し", point: 10, updatedAt: .distantPast)]
            ),
        ]
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                fetchTemplates: { _ in [.init(templateId: Self.inputTemplateId, name: "default")] },
                fetchDays: { _, _ in expectedDays },
                fetchMonthlyItems: { _, _ in throw DomainError.other }
            )
        )

        // Act

        try await store.configure(cohabitantId: Self.inputCohabitantId)

        // Assert

        #expect(store.loadState == .loaded)
        #expect(store.selectedDays == expectedDays)
        #expect(store.monthlyItems == [])

        // Cleanup

        await store.stopObservingItems()
    }

    @Test("startObservingItemsは、二重に監視しないよう既存のリスナーを解除してから開始する")
    func startObservingItemsRemovesExistingListenersFirst() async {
        // Arrange

        let calledOperations = TestLockedArray<String>()
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                addDaysSnapshotListener: { id, _, _ in
                    await calledOperations.append("add:\(id)")
                    return .makeStream().stream
                },
                addMonthlyItemsSnapshotListener: { id, _, _ in
                    await calledOperations.append("add:\(id)")
                    return .makeStream().stream
                },
                removeListener: { id in
                    await calledOperations.append("remove:\(id)")
                }
            )
        )

        // Act

        await store.startObservingItems(templateId: Self.inputTemplateId, cohabitantId: Self.inputCohabitantId)

        // Assert

        let operations = await calledOperations.values
        #expect(operations == [
            "remove:houseworkTemplateDaysListener",
            "remove:houseworkTemplateMonthlyItemsListener",
            "add:houseworkTemplateDaysListener",
            "add:houseworkTemplateMonthlyItemsListener",
        ])
    }

    @Test("MonthlyItemsリスナーで受け取った値がmonthlyItemsに反映される")
    func startObservingItemsReflectsMonthlyItems() async {
        // Arrange

        let (monthlyItemsStream, monthlyItemsContinuation) = AsyncStream<[HouseworkTemplateMonthlyItem]>.makeStream()
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                addMonthlyItemsSnapshotListener: { _, _, _ in monthlyItemsStream }
            )
        )

        // Act

        await store.startObservingItems(
            templateId: Self.inputTemplateId,
            cohabitantId: Self.inputCohabitantId
        )

        // Assert

        let waiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.monthlyItems
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        monthlyItemsContinuation.yield([Self.rent])
        await waiter.value
        #expect(store.monthlyItems == [Self.rent])

        // Cleanup

        monthlyItemsContinuation.finish()
        await store.stopObservingItems()
    }

}
