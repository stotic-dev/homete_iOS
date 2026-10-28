//
//  ForceUpdateStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct ForceUpdateStoreTest {

    @Test("反映済みの最低バージョンを現在のバージョンが下回る場合、強制アップデートが必要になる")
    func updateRequirementRequiresForceUpdate() {
        // Arrange

        let remoteConfigClient = RemoteConfigClient(
            string: { _ in "2.0.0" }
        )
        let store = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )

        // Act

        store.updateRequirement()

        // Assert

        #expect(store.isForceUpdateRequired == true)
    }

    @Test("反映済みの最低バージョンが引き下げられていれば、強制アップデートを解除する")
    func updateRequirementCancelsForceUpdate() {
        // Arrange

        let remoteConfigClient = RemoteConfigClient(
            string: { _ in "1.0.0" }
        )
        let store = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0",
            isForceUpdateRequired: true
        )

        // Act

        store.updateRequirement()

        // Assert

        #expect(store.isForceUpdateRequired == false)
    }

}
