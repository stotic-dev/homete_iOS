//
//  HouseworkTemplateEditStoreTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/05/09.
//

import Foundation
@testable import HometeDomain
@testable import HouseworkTemplateFeature
import Testing

private typealias TestCase = HouseworkTemplateEditStoreTest

// swiftlint:disable:next convenience_type
enum HouseworkTemplateEditStoreTest {

    static let inputCohabitantId = "cohabitantId"
    static let inputTemplateId = "templateId"
    static let inputUserId = "userId"

    @MainActor
    struct StartEditingCase {}

    @MainActor
    struct StopEditingCase {}

    @MainActor
    struct SaveDayCase {}

}

extension HouseworkTemplateEditStoreTest.StartEditingCase {

    @Test("編集モード開始時、Editorをupsertし、initialのversionをcurrentVersionに反映する")
    func startEditing_upsertsEditorAndSetsCurrentVersion() async throws {
        // Arrange

        let now = Date(timeIntervalSince1970: 1_000_000)
        let editorTTL: TimeInterval = 5 * 60
        let inputMeta = HouseworkTemplateMeta(
            templateId: HouseworkTemplateEditStoreTest.inputTemplateId,
            name: "テンプレ",
            version: 5
        )
        let expectedEditor = HouseworkTemplateEditor(
            userId: TestCase.inputUserId,
            updatedAt: now,
            expiredAt: now.addingTimeInterval(editorTTL)
        )
        let upserts = TestLockedArray<TestUpsertedEditorRecord>()
        let store = HouseworkTemplateEditStore(
            houseworkTemplateClient: .init(
                upsertEditor: { editor, templateId, cohabitantId in
                    await upserts.append(
                        .init(editor: editor, templateId: templateId, cohabitantId: cohabitantId)
                    )
                },
                addDaysSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                },
                addEditorsSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                }
            )
        )

        // Act

        try await store.startEditing(
            meta: inputMeta,
            cohabitantId: TestCase.inputCohabitantId,
            userId: TestCase.inputUserId,
            now: now
        )

        // Assert

        #expect(store.currentVersion == 5)
        let records = await upserts.values
        #expect(records.count == 1)
        #expect(records.first?.editor == expectedEditor)
        #expect(records.first?.templateId == TestCase.inputTemplateId)
        #expect(records.first?.cohabitantId == TestCase.inputCohabitantId)

        // Cleanup

        await store.stopEditing(
            templateId: TestCase.inputTemplateId,
            cohabitantId: TestCase.inputCohabitantId,
            userId: TestCase.inputUserId
        )
    }

    @Test("編集モード開始後、Daysリスナーで受け取った値がdaysに反映される")
    func startEditing_reflectsDaysFromListener() async throws {
        // Arrange

        let inputMeta = HouseworkTemplateMeta(
            templateId: TestCase.inputTemplateId,
            name: "テンプレ",
            version: 0
        )
        let expectedDays: [HouseworkTemplateDay] = [
            .init(dayOfWeek: 1, items: [.init(id: .init(id: "id"), title: "ゴミ出し", point: 5, updatedAt: .now)]),
        ]
        let (daysStream, daysContinuation) = AsyncStream<[HouseworkTemplateDay]>.makeStream()
        let store = HouseworkTemplateEditStore(
            houseworkTemplateClient: .init(
                addDaysSnapshotListener: { _, _, _ in daysStream },
                addEditorsSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                }
            )
        )

        // Act

        try await store.startEditing(
            meta: inputMeta,
            cohabitantId: TestCase.inputCohabitantId,
            userId: TestCase.inputUserId,
            now: Date()
        )

        // Assert

        let waiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.days
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        daysContinuation.yield(expectedDays)
        await waiter.value
        #expect(store.days == expectedDays)

        // Cleanup

        daysContinuation.finish()
        await store.stopEditing(
            templateId: TestCase.inputTemplateId,
            cohabitantId: TestCase.inputCohabitantId,
            userId: TestCase.inputUserId
        )
    }

    @Test("編集モード開始後、Editorsリスナーで受け取った値がeditorsに反映される")
    func startEditing_reflectsEditorsFromListener() async throws {
        // Arrange

        let now = Date()
        let inputMeta = HouseworkTemplateMeta(
            templateId: TestCase.inputTemplateId,
            name: "テンプレ",
            version: 0
        )
        let expectedEditors: [HouseworkTemplateEditor] = [
            .init(userId: "otherUser", updatedAt: now, expiredAt: now.addingTimeInterval(300)),
        ]
        let (editorsStream, editorsContinuation) = AsyncStream<[HouseworkTemplateEditor]>.makeStream()
        let store = HouseworkTemplateEditStore(
            houseworkTemplateClient: .init(
                addDaysSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                },
                addEditorsSnapshotListener: { _, _, _ in editorsStream }
            )
        )

        // Act

        try await store.startEditing(
            meta: inputMeta,
            cohabitantId: TestCase.inputCohabitantId,
            userId: TestCase.inputUserId,
            now: now
        )

        // Assert

        let waiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.editors
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        editorsContinuation.yield(expectedEditors)
        await waiter.value
        #expect(store.editors == expectedEditors)

        // Cleanup

        editorsContinuation.finish()
        await store.stopEditing(
            templateId: TestCase.inputTemplateId,
            cohabitantId: TestCase.inputCohabitantId,
            userId: TestCase.inputUserId
        )
    }

}

extension HouseworkTemplateEditStoreTest.StopEditingCase {

    @Test("編集モード終了時、リスナー解除とEditor削除を実行する")
    func stopEditing_removesListenersAndEditor() async {
        // Arrange

        let removedListenerKeys = TestLockedArray<String>()
        let removedEditorUserIds = TestLockedArray<String>()
        let store = HouseworkTemplateEditStore(
            houseworkTemplateClient: .init(
                removeEditor: { userId, _, _ in
                    await removedEditorUserIds.append(userId)
                },
                removeListener: { id in
                    await removedListenerKeys.append(id)
                }
            ),
            currentVersion: 0
        )

        // Act

        await store.stopEditing(
            templateId: TestCase.inputTemplateId,
            cohabitantId: TestCase.inputCohabitantId,
            userId: TestCase.inputUserId
        )

        // Assert

        let listenerKeys = await removedListenerKeys.values
        let editorUserIds = await removedEditorUserIds.values
        #expect(Set(listenerKeys) == Set([
            "houseworkTemplateDaysListener",
            "houseworkTemplateEditorsListener",
        ]))
        #expect(editorUserIds == [TestCase.inputUserId])
    }

}

extension HouseworkTemplateEditStoreTest.SaveDayCase {

    @Test("曜日定義の保存に成功すると、currentVersionが+1される")
    func saveDay_success_incrementsCurrentVersion() async throws {
        // Arrange

        let inputDay = HouseworkTemplateDay(
            dayOfWeek: 1,
            items: [.init(id: .init(id: "id"), title: "洗濯", point: 5, updatedAt: .now)]
        )
        let updateCalls = TestLockedArray<TestUpdateDayRecord>()
        let store = HouseworkTemplateEditStore(
            houseworkTemplateClient: .init(
                updateDay: { day, templateId, cohabitantId, currentVersion in
                    await updateCalls.append(
                        .init(
                            day: day,
                            templateId: templateId,
                            cohabitantId: cohabitantId,
                            currentVersion: currentVersion
                        )
                    )
                }
            ),
            currentVersion: 3
        )

        // Act

        try await store.saveDay(
            inputDay,
            templateId: TestCase.inputTemplateId,
            cohabitantId: TestCase.inputCohabitantId
        )

        // Assert

        #expect(store.currentVersion == 4)
        let calls = await updateCalls.values
        #expect(calls.count == 1)
        #expect(calls.first?.day == inputDay)
        #expect(calls.first?.templateId == TestCase.inputTemplateId)
        #expect(calls.first?.cohabitantId == TestCase.inputCohabitantId)
        #expect(calls.first?.currentVersion == 3)
    }

    @Test("曜日定義の保存でversionConflictが発生すると、エラーがthrowされcurrentVersionは変わらない")
    func saveDay_conflict_throwsAndKeepsVersion() async throws {
        // Arrange

        let inputDay = HouseworkTemplateDay(dayOfWeek: 1, items: [])
        let store = HouseworkTemplateEditStore(
            houseworkTemplateClient: .init(
                updateDay: { _, _, _, _ in
                    throw HouseworkTemplateError.versionConflict
                }
            ),
            currentVersion: 3
        )

        // Act + Assert

        await #expect(throws: HouseworkTemplateError.self) {
            try await store.saveDay(
                inputDay,
                templateId: TestCase.inputTemplateId,
                cohabitantId: TestCase.inputCohabitantId
            )
        }
        #expect(store.currentVersion == 3)
    }

}

// MARK: テスト用のモデル

private actor TestLockedArray<Element: Sendable> {

    var values: [Element] = []

    func append(_ element: Element) {
        values.append(element)
    }

}

private struct TestUpsertedEditorRecord {

    let editor: HouseworkTemplateEditor
    let templateId: String
    let cohabitantId: String

}

private struct TestUpdateDayRecord {

    let day: HouseworkTemplateDay
    let templateId: String
    let cohabitantId: String
    let currentVersion: Int

}
