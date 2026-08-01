//
//  HouseworkTemplateEditStoreMetaVersionListenerTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/05/14.
//

import Foundation
@testable import HometeDomain
@testable import HouseworkTemplateFeature
import Testing

extension HouseworkTemplateEditStoreTest.MetaVersionListenerCase {

    @Test("編集モード開始後、Meta versionリスナーで受け取った値がcurrentVersionに反映される")
    func startEditing_reflectsCurrentVersionFromListener() async throws {
        // Arrange

        let expectedVersion = 7
        let (versionStream, versionContinuation) = AsyncStream<Int>.makeStream()
        let store = HouseworkTemplateEditStore(
            houseworkTemplateClient: .init(
                addDaysSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                },
                addEditorsSnapshotListener: { _, _, _ in
                    AsyncStream { $0.finish() }
                },
                addMetaVersionSnapshotListener: { _, _, _ in versionStream }
            ),
            currentVersion: 0
        )

        // Act

        try await store.startEditing(
            templateId: HouseworkTemplateEditStoreTest.inputTemplateId,
            cohabitantId: HouseworkTemplateEditStoreTest.inputCohabitantId,
            userId: HouseworkTemplateEditStoreTest.inputUserId,
            now: Date()
        )

        // Assert

        let waiter = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.currentVersion
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        versionContinuation.yield(expectedVersion)
        await waiter.value
        #expect(store.currentVersion == expectedVersion)

        // Cleanup

        versionContinuation.finish()
        await store.stopEditing(
            templateId: HouseworkTemplateEditStoreTest.inputTemplateId,
            cohabitantId: HouseworkTemplateEditStoreTest.inputCohabitantId,
            userId: HouseworkTemplateEditStoreTest.inputUserId
        )
    }

}
