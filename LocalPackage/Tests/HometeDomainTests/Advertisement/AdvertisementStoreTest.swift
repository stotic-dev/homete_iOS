//
//  AdvertisementStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct AdvertisementStoreTest {

    @Test("起動時の取得が終わるまでは、広告表示はアプリ内デフォルト値の無効になる")
    func initialAdsEnabledIsDefault() {
        // Arrange

        let remoteConfigClient = RemoteConfigClient(bool: { _ in true })

        // Act

        let store = AdvertisementStore(remoteConfigClient: remoteConfigClient)

        // Assert

        #expect(store.isAdsEnabled == false)
    }

    @Test(
        "反映済みの値で広告表示の有無を確定する",
        arguments: [true, false]
    )
    func confirmAdsEnabled(remoteValue: Bool) {
        // Arrange

        let remoteConfigClient = RemoteConfigClient(
            bool: { key in
                #expect(key == .adsEnabled)
                return remoteValue
            }
        )
        let store = AdvertisementStore(
            remoteConfigClient: remoteConfigClient,
            isAdsEnabled: !remoteValue
        )

        // Act

        store.confirmAdsEnabled()

        // Assert

        #expect(store.isAdsEnabled == remoteValue)
    }

}
