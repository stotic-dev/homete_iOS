//
//  RevenueCatClient.swift
//  LocalPackage
//

#if os(iOS)
import Foundation
import RevenueCat

public final class RevenueCatClient: Sendable {

    public static let shared = RevenueCatClient()

    public func initialize() {
        let testStoreEnabledValue = Bundle.main
            .object(forInfoDictionaryKey: "REVENUECAT_TEST_STORE_ENABLED") as? String
        let apiKeyInfoKey = testStoreEnabledValue == "YES" ? "REVENUECAT_TEST_STORE_API_KEY" : "REVENUECAT_API_KEY"

        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: apiKeyInfoKey) as? String,
              !apiKey.isEmpty else {
            assertionFailure("\(apiKeyInfoKey) is not configured")
            return
        }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: apiKey)
    }

}
#endif
