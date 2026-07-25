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
            guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
                  !apiKey.isEmpty else {
                assertionFailure("REVENUECAT_API_KEY is not configured")
                return
            }

            Purchases.configure(withAPIKey: apiKey)
        }

    }
#endif
