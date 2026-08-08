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
            return makeEntitlementInfo(from: customerInfo)
        },
        entitlementInfoUpdates: {
            AsyncStream { continuation in
                Task {
                    for await customerInfo in Purchases.shared.customerInfoStream {
                        continuation.yield(makeEntitlementInfo(from: customerInfo))
                    }
                    continuation.finish()
                }
            }
        },
        showManageSubscriptions: {
            try await Purchases.shared.showManageSubscriptions()
        }
    )

}

private let premiumEntitlementId = "taichi sato Pro"

private func makeEntitlementInfo(from customerInfo: CustomerInfo) -> HometeDomain.EntitlementInfo {
    let entitlement = customerInfo.entitlements[premiumEntitlementId]
    return HometeDomain.EntitlementInfo(
        isActive: entitlement?.isActive == true,
        productIdentifier: entitlement?.productIdentifier ?? "",
        expirationDate: entitlement?.expirationDate
    )
}
#endif
