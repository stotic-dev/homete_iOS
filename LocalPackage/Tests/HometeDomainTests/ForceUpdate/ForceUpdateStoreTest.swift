//
//  ForceUpdateStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct ForceUpdateStoreTest {

    private struct FetchError: Error {}

    @Test("起動時に取得・反映した最低バージョンを現在のバージョンが下回る場合、強制アップデートが必要になる")
    func setupOnLaunchRequiresForceUpdate() async {
        // Arrange

        let isActivated = TestBox(value: false)
        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                isActivated.value = true
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
        let store = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )

        // Act

        await store.setupOnLaunch()

        // Assert

        #expect(store.forceUpdateRequirement == .init(message: "案内"))
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
        let store = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )
        storeBox.value = store

        // Act

        await store.setupOnLaunch()

        // Assert

        #expect(requirementDuringFetch.value == .init(message: nil))
    }

    @Test("起動時の取得に失敗した場合も、前回反映済みの最低バージョンで強制アップデートを判定する")
    func setupOnLaunchFailureUsesActivatedMinimumVersion() async {
        // Arrange

        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                throw FetchError()
            },
            string: { key in
                // 前回の起動で反映済みの値
                key == .minimumRequiredVersion ? "2.0.0" : key.defaultValue
            }
        )
        let store = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )

        // Act

        await store.setupOnLaunch()

        // Assert

        #expect(store.forceUpdateRequirement == .init(message: nil))
    }

    @Test("フォアグラウンド復帰時に最低バージョンが引き上げられていれば、強制アップデートが必要になる")
    func refreshRequiresForceUpdate() async {
        // Arrange

        let isActivated = TestBox(value: false)
        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                isActivated.value = true
            },
            string: { key in
                key == .minimumRequiredVersion && isActivated.value ? "2.0.0" : key.defaultValue
            }
        )
        let store = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )

        // Act

        await store.refresh()

        // Assert

        #expect(store.forceUpdateRequirement == .init(message: nil))
    }

    @Test("フォアグラウンド復帰時に最低バージョンが引き下げられていれば、強制アップデートを解除する")
    func refreshCancelsForceUpdate() async {
        // Arrange

        let remoteConfigClient = RemoteConfigClient(
            string: { key in
                key == .minimumRequiredVersion ? "1.0.0" : key.defaultValue
            }
        )
        let store = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0",
            forceUpdateRequirement: .init(message: nil)
        )

        // Act

        await store.refresh()

        // Assert

        #expect(store.forceUpdateRequirement == nil)
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
            string: { key in
                key == .minimumRequiredVersion && isActivated.value ? "2.0.0" : key.defaultValue
            }
        )
        let store = ForceUpdateStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0"
        )

        // Act

        await store.observeConfigUpdates()

        // Assert

        #expect(store.forceUpdateRequirement == .init(message: nil))
    }

}
