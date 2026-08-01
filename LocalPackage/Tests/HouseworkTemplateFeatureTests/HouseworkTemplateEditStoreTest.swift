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

enum HouseworkTemplateEditStoreTest {

    static let inputCohabitantId = "cohabitantId"
    static let inputTemplateId = "templateId"
    static let inputUserId = "userId"

    @MainActor
    struct StartEditingCase {}

    @MainActor
    struct StopEditingCase {}

    @MainActor
    struct MetaVersionListenerCase {}

}

extension HouseworkTemplateEditStoreTest.StartEditingCase {

    @Test("編集モード開始時、Editorをupsertする")
    func startEditing_upsertsEditor() async throws {
        // Arrange

        let now = Date(timeIntervalSince1970: 1_000_000)
        let editorTTL: TimeInterval = 5 * 60
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
                addEditorsSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                },
                addMetaVersionSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                }
            )
        )

        // Act

        try await store.startEditing(
            templateId: TestCase.inputTemplateId,
            cohabitantId: TestCase.inputCohabitantId,
            userId: TestCase.inputUserId,
            now: now
        )

        // Assert

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

    @Test("編集モード開始後、Editorsリスナーで受け取った値がeditorsに反映される")
    func startEditing_reflectsEditorsFromListener() async throws {
        // Arrange

        let now = Date()
        let expectedEditors: [HouseworkTemplateEditor] = [
            .init(userId: "otherUser", updatedAt: now, expiredAt: now.addingTimeInterval(300)),
        ]
        let (editorsStream, editorsContinuation) = AsyncStream<[HouseworkTemplateEditor]>.makeStream()
        let store = HouseworkTemplateEditStore(
            houseworkTemplateClient: .init(
                addEditorsSnapshotListener: { _, _, _ in editorsStream },
                addMetaVersionSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                }
            )
        )

        // Act

        try await store.startEditing(
            templateId: TestCase.inputTemplateId,
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

    @Test("Editorsリスナーで受け取った値のうち、自身のuserIdに一致するEditorはeditorsから除外される")
    func startEditing_excludesOwnEditorFromListener() async throws {
        // Arrange

        let now = Date()
        let otherEditor = HouseworkTemplateEditor(
            userId: "otherUser",
            updatedAt: now,
            expiredAt: now.addingTimeInterval(300)
        )
        let ownEditor = HouseworkTemplateEditor(
            userId: TestCase.inputUserId,
            updatedAt: now,
            expiredAt: now.addingTimeInterval(300)
        )
        let expectedEditors: [HouseworkTemplateEditor] = [otherEditor]
        let (editorsStream, editorsContinuation) = AsyncStream<[HouseworkTemplateEditor]>.makeStream()
        let store = HouseworkTemplateEditStore(
            houseworkTemplateClient: .init(
                addEditorsSnapshotListener: { _, _, _ in editorsStream },
                addMetaVersionSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                }
            )
        )

        // Act

        try await store.startEditing(
            templateId: TestCase.inputTemplateId,
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
        editorsContinuation.yield([otherEditor, ownEditor])
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
            "houseworkTemplateEditorsListener",
            "houseworkTemplateMetaVersionListener",
        ]))
        #expect(editorUserIds == [TestCase.inputUserId])
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
