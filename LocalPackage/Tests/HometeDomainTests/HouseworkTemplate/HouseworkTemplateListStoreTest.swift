//
//  HouseworkTemplateListStoreTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/05/09.
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkTemplateListStoreTest {

    private nonisolated static let inputCohabitantId = "cohabitantId"
    private nonisolated static let inputTemplateId = "templateId"

    @Test("テンプレート一覧の取得を行うと、Clientから受け取ったテンプレート一覧をtemplatesに反映する")
    func loadTemplates() async throws {
        // Arrange

        let expectedTemplates: [HouseworkTemplateMeta] = [
            .init(templateId: "template1", name: "平日テンプレ"),
            .init(templateId: "template2", name: "週末テンプレ"),
        ]
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                fetchTemplates: { cohabitantId in
                    #expect(cohabitantId == Self.inputCohabitantId)
                    return expectedTemplates
                }
            )
        )

        // Act

        try await store.loadTemplates(cohabitantId: Self.inputCohabitantId)

        // Assert

        #expect(store.templates == expectedTemplates)
    }

    @Test("曜日定義の取得を行うと、Clientから受け取った定義をselectedDaysに反映する")
    func loadDays() async throws {
        // Arrange

        let expectedDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: .monday,
                items: [.init(id: .init(id: "id"), title: "ゴミ出し", point: 10, updatedAt: .now)]
            ),
        ]
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                fetchDays: { cohabitantId, templateId in
                    #expect(cohabitantId == Self.inputCohabitantId)
                    #expect(templateId == Self.inputTemplateId)
                    return expectedDays
                }
            )
        )

        // Act

        try await store.loadDays(templateId: Self.inputTemplateId, cohabitantId: Self.inputCohabitantId)

        // Assert

        #expect(store.selectedDays == expectedDays)
    }

    @Test("テンプレートを新規作成すると、Clientにメタを書き込みtemplatesにも追加する")
    func createTemplate() async throws {
        // Arrange

        let inputTemplateId = "newTemplateId"
        let inputName = "新しいテンプレ"
        let expectedMeta = HouseworkTemplateMeta(
            templateId: inputTemplateId,
            name: inputName
        )

        try await confirmation { confirmation in
            let store = HouseworkTemplateListStore(
                houseworkTemplateClient: .init(
                    upsertTemplate: { meta, cohabitantId in
                        // Assert

                        #expect(meta == expectedMeta)
                        #expect(cohabitantId == Self.inputCohabitantId)
                        confirmation()
                    }
                )
            )

            // Act

            try await store.createTemplate(
                templateId: inputTemplateId,
                name: inputName,
                cohabitantId: Self.inputCohabitantId
            )

            // Assert

            #expect(store.templates == [expectedMeta])
        }
    }

    @Test("saveDaysが成功すると、updateDaysが呼ばれselectedDaysの該当dayOfWeekが置き換えられ、未登録は追加される")
    func saveDaysMergesIntoSelectedDays() async throws {
        // Arrange

        let initialDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: .monday,
                items: [.init(id: .init(id: "old"), title: "古い家事", point: 1, updatedAt: .now)]
            ),
            .init(
                dayOfWeek: .wednesday,
                items: [.init(id: .init(id: "wed"), title: "水曜", point: 2, updatedAt: .now)]
            ),
        ]
        let inputDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: .monday,
                items: [.init(id: .init(id: "new"), title: "新しい家事", point: 5, updatedAt: .now)]
            ),
            .init(
                dayOfWeek: .friday,
                items: [.init(id: .init(id: "fri"), title: "金曜", point: 3, updatedAt: .now)]
            ),
        ]
        let inputCurrentVersion = 3
        let expectedDays: [HouseworkTemplateDay] = [
            inputDays[0],
            initialDays[1],
            inputDays[1],
        ]

        try await confirmation { confirmation in
            let store = HouseworkTemplateListStore(
                houseworkTemplateClient: .init(
                    updateDays: { days, templateId, cohabitantId, currentVersion in
                        #expect(days == inputDays)
                        #expect(templateId == Self.inputTemplateId)
                        #expect(cohabitantId == Self.inputCohabitantId)
                        #expect(currentVersion == inputCurrentVersion)
                        confirmation()
                    }
                ),
                selectedDays: initialDays
            )

            // Act

            try await store.saveDays(
                inputDays,
                templateId: Self.inputTemplateId,
                cohabitantId: Self.inputCohabitantId,
                currentVersion: inputCurrentVersion
            )

            // Assert

            #expect(store.selectedDays == expectedDays)
        }
    }

    @Test("saveDaysに空配列を渡すと、updateDaysは呼ばれずselectedDaysも変わらない")
    func saveDaysWithEmptyIsNoop() async throws {
        // Arrange

        let initialDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: .monday,
                items: [.init(id: .init(id: "mon"), title: "月曜", point: 1, updatedAt: .now)]
            ),
        ]
        let updateCallCount = TestCounter()
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                updateDays: { _, _, _, _ in await updateCallCount.increment() }
            ),
            selectedDays: initialDays
        )

        // Act

        try await store.saveDays(
            [],
            templateId: Self.inputTemplateId,
            cohabitantId: Self.inputCohabitantId,
            currentVersion: 0
        )

        // Assert

        let count = await updateCallCount.value
        #expect(count == 0)
        #expect(store.selectedDays == initialDays)
    }

    @Test("saveDaysでversionConflictが発生すると、エラーがthrowされselectedDaysは変わらない")
    func saveDaysConflictKeepsSelectedDays() async throws {
        // Arrange

        let initialDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: .monday,
                items: [.init(id: .init(id: "mon"), title: "月曜", point: 1, updatedAt: .now)]
            ),
        ]
        let inputDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: .monday,
                items: [.init(id: .init(id: "new"), title: "新", point: 9, updatedAt: .now)]
            ),
        ]
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                updateDays: { _, _, _, _ in throw HouseworkTemplateError.versionConflict }
            ),
            selectedDays: initialDays
        )

        // Act + Assert

        await #expect(throws: HouseworkTemplateError.self) {
            try await store.saveDays(
                inputDays,
                templateId: Self.inputTemplateId,
                cohabitantId: Self.inputCohabitantId,
                currentVersion: 0
            )
        }
        #expect(store.selectedDays == initialDays)
    }

    @Test("Daysリスナーで受け取った値がselectedDaysに反映される")
    func startObservingDaysReflectsValues() async {
        // Arrange

        let expectedDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: .tuesday,
                items: [.init(id: .init(id: "id"), title: "火曜", point: 4, updatedAt: .now)]
            ),
        ]
        let (daysStream, daysContinuation) = AsyncStream<[HouseworkTemplateDay]>.makeStream()
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                addDaysSnapshotListener: { _, _, _ in daysStream }
            )
        )

        // Act

        await store.startObservingDays(
            templateId: Self.inputTemplateId,
            cohabitantId: Self.inputCohabitantId
        )

        // Assert

        let waiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.selectedDays
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        daysContinuation.yield(expectedDays)
        await waiter.value
        #expect(store.selectedDays == expectedDays)

        // Cleanup

        daysContinuation.finish()
        await store.stopObservingDays()
    }

    @Test("stopObservingDaysでDaysリスナーが解除される")
    func stopObservingDaysRemovesListener() async {
        // Arrange

        let removedListenerKeys = TestLockedArray<String>()
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                removeListener: { id in
                    await removedListenerKeys.append(id)
                }
            )
        )

        // Act

        await store.stopObservingDays()

        // Assert

        let keys = await removedListenerKeys.values
        #expect(keys == ["houseworkTemplateDaysListener"])
    }

}

extension HouseworkTemplateListStoreTest {

    @Test("テンプレートを新規作成すると、selectedTemplateIdが新規IDに更新されselectedDaysは空になる")
    func createTemplateUpdatesSelection() async throws {
        // Arrange

        let inputTemplateId = "newTemplateId"
        let inputName = "新しいテンプレ"
        let initialDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: .monday,
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
                dayOfWeek: .monday,
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
