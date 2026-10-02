//
//  RemoteConfigStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct RemoteConfigStoreTest {

    private struct FetchError: Error {}

    @Test("起動時の取得が終わるまでは、広告表示はアプリ内デフォルト値の無効になる")
    func initialAdsEnabledIsDefault() {
        // Arrange

        let remoteConfigClient = RemoteConfigClient(bool: { _ in true })

        // Act

        let store = RemoteConfigStore(remoteConfigClient: remoteConfigClient)

        // Assert

        #expect(store.isAdsEnabled == false)
    }

    @Test(
        "起動時に取得・反映した後の値で広告表示の有無を確定する",
        arguments: [true, false]
    )
    func setupOnLaunchSuccess(remoteValue: Bool) async {
        // Arrange

        let isActivated = TestBox(value: false)
        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                isActivated.value = true
            },
            bool: { key in
                #expect(key == .adsEnabled)
                // 反映前に読むとデフォルト値が返る
                return isActivated.value ? remoteValue : key.defaultValue
            }
        )
        let store = RemoteConfigStore(
            remoteConfigClient: remoteConfigClient,
            isAdsEnabled: !remoteValue
        )

        // Act

        await store.setupOnLaunch()

        // Assert

        #expect(store.isAdsEnabled == remoteValue)
    }

    @Test("起動時の取得に失敗した場合は、前回反映済みの値で広告表示の有無を確定する")
    func setupOnLaunchFailure() async {
        // Arrange

        let remoteConfigClient = RemoteConfigClient(
            fetchAndActivate: {
                throw FetchError()
            },
            bool: { _ in
                // 前回の起動で反映済みの値
                true
            }
        )
        let store = RemoteConfigStore(remoteConfigClient: remoteConfigClient)

        // Act

        await store.setupOnLaunch()

        // Assert

        #expect(store.isAdsEnabled == true)
    }

    @Test("フォアグラウンド復帰時は最新の値を取得するが、起動中の広告表示の有無は変えない")
    func refreshKeepsAdsEnabled() async {
        await confirmation { confirmation in
            // Arrange

            let remoteConfigClient = RemoteConfigClient(
                fetchAndActivate: {
                    confirmation()
                },
                bool: { _ in
                    Issue.record("起動中は広告表示の値を読み直さない")
                    return true
                }
            )
            let store = RemoteConfigStore(
                remoteConfigClient: remoteConfigClient,
                isAdsEnabled: false
            )

            // Act

            await store.refresh()

            // Assert

            #expect(store.isAdsEnabled == false)
        }
    }

}

// MARK: - 強制アップデート

extension RemoteConfigStoreTest {

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
        let store = RemoteConfigStore(
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

        let storeBox = TestBox<RemoteConfigStore?>(value: nil)
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
        let store = RemoteConfigStore(
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
        let store = RemoteConfigStore(
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
        let store = RemoteConfigStore(
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
        let store = RemoteConfigStore(
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
            bool: { _ in
                Issue.record("起動中は広告表示の値を読み直さない")
                return true
            },
            string: { key in
                key == .minimumRequiredVersion && isActivated.value ? "2.0.0" : key.defaultValue
            }
        )
        let store = RemoteConfigStore(
            remoteConfigClient: remoteConfigClient,
            currentAppVersion: "1.0.0",
            isAdsEnabled: false
        )

        // Act

        await store.observeConfigUpdates()

        // Assert

        #expect(store.forceUpdateRequirement == .init(message: nil))
        #expect(store.isAdsEnabled == false)
    }

}
