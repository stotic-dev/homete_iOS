//
//  RemoteConfigSyncUseCaseTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct RemoteConfigSyncUseCaseTest {

    private struct FetchError: Error {}

    @Test("起動時は取得・反映した後の値で、広告表示の有無を確定し強制アップデートを判定する")
    func setupOnLaunchSuccess() async {
        // Arrange

        let isActivated = TestBox(value: false)
        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                isActivated.value = true
            },
            bool: { key in
                // 反映前に読むとデフォルト値が返る
                isActivated.value ? true : key.defaultValue
            },
            string: { key in
                isActivated.value ? "2.0.0" : key.defaultValue
            }
        )
        let advertisementStore = AdvertisementStore(remoteConfigClient: remoteConfigClient)
        let forceUpdateStore = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )
        let useCase = RemoteConfigSyncUseCase(
            remoteConfigClient: remoteConfigClient,
            advertisementStore: advertisementStore,
            forceUpdateStore: forceUpdateStore,
            maintenanceStore: MaintenanceStore(remoteConfigClient: remoteConfigClient)
        )

        // Act

        await useCase.setupOnLaunch()

        // Assert

        #expect(advertisementStore.isAdsEnabled == true)
        #expect(forceUpdateStore.isForceUpdateRequired == true)
    }

    @Test("起動時は取得の完了を待たずに、前回反映済みの最低バージョンで強制アップデートを判定する")
    func setupOnLaunchUsesActivatedMinimumVersionBeforeFetch() async {
        // Arrange

        let storeBox = TestBox<ForceUpdateStore?>(value: nil)
        let requirementDuringFetch = TestBox<Bool?>(value: nil)
        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                requirementDuringFetch.value = await storeBox.value?.isForceUpdateRequired
            },
            // 前回の起動で反映済みの値
            string: { _ in "2.0.0" }
        )
        let forceUpdateStore = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )
        storeBox.value = forceUpdateStore
        let useCase = RemoteConfigSyncUseCase(
            remoteConfigClient: remoteConfigClient,
            advertisementStore: AdvertisementStore(remoteConfigClient: remoteConfigClient),
            forceUpdateStore: forceUpdateStore,
            maintenanceStore: MaintenanceStore(remoteConfigClient: remoteConfigClient)
        )

        // Act

        await useCase.setupOnLaunch()

        // Assert

        #expect(requirementDuringFetch.value == true)
    }

    @Test("起動時の取得に失敗した場合は、前回反映済みの値で広告表示の有無を確定し強制アップデートを判定する")
    func setupOnLaunchFailure() async {
        // Arrange

        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                throw FetchError()
            },
            // 前回の起動で反映済みの値
            bool: { _ in true },
            string: { _ in "2.0.0" }
        )
        let advertisementStore = AdvertisementStore(remoteConfigClient: remoteConfigClient)
        let forceUpdateStore = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )
        let useCase = RemoteConfigSyncUseCase(
            remoteConfigClient: remoteConfigClient,
            advertisementStore: advertisementStore,
            forceUpdateStore: forceUpdateStore,
            maintenanceStore: MaintenanceStore(remoteConfigClient: remoteConfigClient)
        )

        // Act

        await useCase.setupOnLaunch()

        // Assert

        #expect(advertisementStore.isAdsEnabled == true)
        #expect(forceUpdateStore.isForceUpdateRequired == true)
    }

    @Test("フォアグラウンド復帰時は、起動中の広告表示の有無を変えずに強制アップデートとメンテナンスを判定し直す")
    func refresh() async {
        // Arrange

        let isActivated = TestBox(value: false)
        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                isActivated.value = true
            },
            bool: { key in
                if key == .adsEnabled {
                    Issue.record("起動中は広告表示の値を読み直さない")
                }
                return true
            },
            string: { key in
                isActivated.value ? "2.0.0" : key.defaultValue
            }
        )
        let advertisementStore = AdvertisementStore(
            remoteConfigClient: remoteConfigClient,
            isAdsEnabled: false
        )
        let forceUpdateStore = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )
        let maintenanceStore = MaintenanceStore(remoteConfigClient: remoteConfigClient)
        let useCase = RemoteConfigSyncUseCase(
            remoteConfigClient: remoteConfigClient,
            advertisementStore: advertisementStore,
            forceUpdateStore: forceUpdateStore,
            maintenanceStore: maintenanceStore
        )

        // Act

        await useCase.refresh()

        // Assert

        #expect(advertisementStore.isAdsEnabled == false)
        #expect(forceUpdateStore.isForceUpdateRequired == true)
        #expect(maintenanceStore.isUnderMaintenance == true)
    }

    @Test("コンソールで公開された最低バージョンの変更を受け取ると、強制アップデートを判定し直す")
    func observeConfigUpdatesRequiresForceUpdate() async {
        // Arrange

        let isActivated = TestBox(value: false)
        let remoteConfigClient = RemoteConfigClient(
            configUpdates: {
                AsyncStream { continuation in
                    isActivated.value = true
                    continuation.yield()
                    continuation.finish()
                }
            },
            bool: { key in
                if key == .adsEnabled {
                    Issue.record("起動中は広告表示の値を読み直さない")
                }
                return true
            },
            string: { key in
                isActivated.value ? "2.0.0" : key.defaultValue
            }
        )
        let forceUpdateStore = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )
        let useCase = RemoteConfigSyncUseCase(
            remoteConfigClient: remoteConfigClient,
            advertisementStore: AdvertisementStore(remoteConfigClient: remoteConfigClient),
            forceUpdateStore: forceUpdateStore,
            maintenanceStore: MaintenanceStore(remoteConfigClient: remoteConfigClient)
        )

        // Act

        await useCase.observeConfigUpdates()

        // Assert

        #expect(forceUpdateStore.isForceUpdateRequired == true)
    }

    @Test("コンソールでメンテナンスを終えた変更を受け取ると、メンテナンスを解除する")
    func observeConfigUpdatesEndsMaintenance() async {
        // Arrange

        let isActivated = TestBox(value: false)
        let remoteConfigClient = RemoteConfigClient(
            configUpdates: {
                AsyncStream { continuation in
                    isActivated.value = true
                    continuation.yield()
                    continuation.finish()
                }
            },
            bool: { key in
                key == .maintenanceEnabled ? !isActivated.value : key.defaultValue
            }
        )
        let maintenanceStore = MaintenanceStore(
            remoteConfigClient: remoteConfigClient,
            isUnderMaintenance: true
        )
        let useCase = RemoteConfigSyncUseCase(
            remoteConfigClient: remoteConfigClient,
            advertisementStore: AdvertisementStore(remoteConfigClient: remoteConfigClient),
            forceUpdateStore: ForceUpdateStore(remoteConfigClient: remoteConfigClient),
            maintenanceStore: maintenanceStore
        )

        // Act

        await useCase.observeConfigUpdates()

        // Assert

        #expect(maintenanceStore.isUnderMaintenance == false)
    }

}
