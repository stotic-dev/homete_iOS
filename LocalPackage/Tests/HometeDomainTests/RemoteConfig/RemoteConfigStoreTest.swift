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
