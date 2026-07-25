//
//  AppDependencies+liveValue.swift
//

#if os(iOS)
    import HometeDomain

    // MARK: Live用の定義

    public extension AppDependencies {

        static let liveValue: Self = .init(
            nonceGeneratorClient: .liveValue,
            accountAuthClient: .liveValue,
            analyticsClient: .liveValue,
            accountInfoClient: .liveValue,
            cohabitantClient: .liveValue,
            houseworkClient: .liveValue,
            cohabitantPushNotificationClient: .liveValue,
            signInWithAppleClient: .liveValue,
            purchaseClient: .liveValue
        )

    }
#endif
