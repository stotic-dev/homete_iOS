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
            }
        )

    }

    private let premiumEntitlementId = "taichi sato Pro"
#endif
