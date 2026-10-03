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
                switch key {
                case .minimumRequiredVersion:
                    isActivated.value ? "2.0.0" : key.defaultValue
                case .forceUpdateMessage:
                    isActivated.value ? "案内" : key.defaultValue
                }
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
            forceUpdateStore: forceUpdateStore
        )

        // Act

        await useCase.setupOnLaunch()

        // Assert

        #expect(advertisementStore.isAdsEnabled == true)
        #expect(forceUpdateStore.forceUpdateRequirement == .init(message: "案内"))
    }

    @Test("起動時は取得の完了を待たずに、前回反映済みの最低バージョンで強制アップデートを判定する")
    func setupOnLaunchUsesActivatedMinimumVersionBeforeFetch() async {
        // Arrange

        let storeBox = TestBox<ForceUpdateStore?>(value: nil)
        let requirementDuringFetch = TestBox<ForceUpdateRequirement?>(value: nil)
        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                requirementDuringFetch.value = await storeBox.value?.forceUpdateRequirement
            },
            string: { key in
                // 前回の起動で反映済みの値
                key == .minimumRequiredVersion ? "2.0.0" : key.defaultValue
            }
        )
        let forceUpdateStore = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )
        storeBox.value = forceUpdateStore
        let useCase = RemoteConfigSyncUseCase(
            remoteConfigClient: remoteConfigClient,
            advertisementStore: AdvertisementStore(remoteConfigClient: remoteConfigClient),
            forceUpdateStore: forceUpdateStore
        )

        // Act

        await useCase.setupOnLaunch()

        // Assert

        #expect(requirementDuringFetch.value == .init(message: nil))
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
            string: { key in
                key == .minimumRequiredVersion ? "2.0.0" : key.defaultValue
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
            forceUpdateStore: forceUpdateStore
        )

        // Act

        await useCase.setupOnLaunch()

        // Assert

        #expect(advertisementStore.isAdsEnabled == true)
        #expect(forceUpdateStore.forceUpdateRequirement == .init(message: nil))
    }

    @Test("フォアグラウンド復帰時は、起動中の広告表示の有無を変えずに強制アップデートを判定し直す")
    func refresh() async {
        // Arrange

        let isActivated = TestBox(value: false)
        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                isActivated.value = true
            },
            bool: { _ in
                Issue.record("起動中は広告表示の値を読み直さない")
                return true
            },
            string: { key in
                key == .minimumRequiredVersion && isActivated.value ? "2.0.0" : key.defaultValue
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
        let useCase = RemoteConfigSyncUseCase(
            remoteConfigClient: remoteConfigClient,
            advertisementStore: advertisementStore,
            forceUpdateStore: forceUpdateStore
        )

        // Act

        await useCase.refresh()

        // Assert

        #expect(advertisementStore.isAdsEnabled == false)
        #expect(forceUpdateStore.forceUpdateRequirement == .init(message: nil))
    }

}
