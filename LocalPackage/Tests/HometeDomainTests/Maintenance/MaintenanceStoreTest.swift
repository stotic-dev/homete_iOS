//
//  MaintenanceStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct MaintenanceStoreTest {

    @Test("反映済みの値でメンテナンス中かどうかを判定し、Notification Service Extensionと共有する", arguments: [true, false])
    func updateState(isMaintenanceEnabled: Bool) {
        // Arrange

        let savedState = TestBox<Bool?>(value: nil)
        let store = MaintenanceStore(
            remoteConfigClient: .init(bool: { key in
                key == .maintenanceEnabled ? isMaintenanceEnabled : key.defaultValue
            }),
            maintenanceStateClient: .init(save: { savedState.value = $0 }),
            isUnderMaintenance: !isMaintenanceEnabled
        )

        // Act

        store.updateState()

        // Assert

        #expect(store.isUnderMaintenance == isMaintenanceEnabled)
        #expect(savedState.value == isMaintenanceEnabled)
    }

    @Test("一度も値を反映できていない場合は、アプリ内デフォルト値でメンテナンス中にしない")
    func updateStateWithDefaultValue() {
        // Arrange

        let store = MaintenanceStore(
            remoteConfigClient: .init(),
            isUnderMaintenance: true
        )

        // Act

        store.updateState()

        // Assert

        #expect(store.isUnderMaintenance == false)
    }

}
