//
//  HouseworkTemplateListStoreConfigureTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/05/20.
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkTemplateListStoreConfigureTest {

    private nonisolated static let inputCohabitantId = "cohabitantId"

    @Test("テンプレートを新規作成すると、selectedTemplateIdが新規IDに更新されselectedDaysは空になる")
    func createTemplateUpdatesSelection() async throws {
        // Arrange

        let inputTemplateId = "newTemplateId"
        let inputName = "新しいテンプレ"
        let initialDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: 1,
                items: [.init(id: .init(id: "old"), title: "古い家事", point: 1, updatedAt: .now)]
            ),
        ]
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(),
            selectedDays: initialDays,
            selectedTemplateId: "previousTemplateId"
        )

        // Act

        try await store.createTemplate(
            templateId: inputTemplateId,
            name: inputName,
            cohabitantId: Self.inputCohabitantId
        )

        // Assert

        #expect(store.selectedTemplateId == inputTemplateId)
        #expect(store.selectedDays == [])
    }

    @Test("configureを呼ぶと、テンプレート一覧の取得・先頭テンプレートのDays取得・監視開始が行われる")
    func configureLoadsTemplatesAndSelectsFirst() async throws {
        // Arrange

        let inputTemplateId = "first"
        let expectedTemplates: [HouseworkTemplateMeta] = [
            .init(templateId: inputTemplateId, name: "平日テンプレ"),
            .init(templateId: "second", name: "週末テンプレ"),
        ]
        let expectedDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: 1,
                items: [.init(id: .init(id: "id"), title: "ゴミ出し", point: 10, updatedAt: .now)]
            ),
        ]
        let (daysStream, daysContinuation) = AsyncStream<[HouseworkTemplateDay]>.makeStream()
        let listenerStartedKeys = TestLockedArray<String>()
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                fetchTemplates: { cohabitantId in
                    #expect(cohabitantId == Self.inputCohabitantId)
                    return expectedTemplates
                },
                fetchDays: { cohabitantId, templateId in
                    #expect(cohabitantId == Self.inputCohabitantId)
                    #expect(templateId == inputTemplateId)
                    return expectedDays
                },
                addDaysSnapshotListener: { id, templateId, cohabitantId in
                    await listenerStartedKeys.append(id)
                    #expect(templateId == inputTemplateId)
                    #expect(cohabitantId == Self.inputCohabitantId)
                    return daysStream
                }
            )
        )

        // Act

        try await store.configure(cohabitantId: Self.inputCohabitantId)

        // Assert

        #expect(store.templates == expectedTemplates)
        #expect(store.selectedTemplateId == inputTemplateId)
        #expect(store.selectedDays == expectedDays)
        let startedKeys = await listenerStartedKeys.values
        #expect(startedKeys == ["houseworkTemplateDaysListener"])

        // Cleanup

        daysContinuation.finish()
        await store.stopObservingDays()
    }

    @Test("configureを呼んでテンプレートが0件の場合は、selectedTemplateIdとselectedDaysは初期状態のまま変化しない")
    func configureDoesNothingWhenTemplatesEmpty() async throws {
        // Arrange

        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                fetchTemplates: { _ in [] },
                fetchDays: { _, _ in
                    Issue.record()
                    return []
                },
                addDaysSnapshotListener: { _, _, _ in
                    Issue.record()
                    return .makeStream().stream
                }
            )
        )

        // Act

        try await store.configure(cohabitantId: Self.inputCohabitantId)

        // Assert

        #expect(store.templates == [])
        #expect(store.selectedTemplateId == nil)
        #expect(store.selectedDays == [])
    }

}

private actor TestLockedArray<Element: Sendable> {

    var values: [Element] = []

    func append(_ element: Element) {
        values.append(element)
    }

}
