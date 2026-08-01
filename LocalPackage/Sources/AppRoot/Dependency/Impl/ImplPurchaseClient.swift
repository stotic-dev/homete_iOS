//
//  ImplPurchaseClient.swift
//

#if os(iOS)
import HometeDomain
import RevenueCat

extension PurchaseClient {

    static let liveValue: PurchaseClient = .init(
        logIn: { accountId in
            _ = try await Purchases.shared.logIn(accountId)
        },
        logOut: {
            _ = try await Purchases.shared.logOut()
        },
        fetchEntitlementInfo: {
            let customerInfo = try await Purchases.shared.customerInfo()
            let isActive = customerInfo.entitlements[premiumEntitlementId]?.isActive == true
            return EntitlementInfo(isActive: isActive)
        },
        entitlementInfoUpdates: {
            AsyncStream { continuation in
                Task {
                    for await customerInfo in Purchases.shared.customerInfoStream {
                        let isActive = customerInfo.entitlements[premiumEntitlementId]?.isActive == true
                        continuation.yield(EntitlementInfo(isActive: isActive))
                    }
                    continuation.finish()
                }
            }
        }
    )

}

private let premiumEntitlementId = "taichi sato Pro"
#endif
