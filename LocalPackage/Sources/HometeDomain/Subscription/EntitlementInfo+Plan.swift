//
//  EntitlementInfo+Plan.swift
//  LocalPackage
//

public extension EntitlementInfo {

    var plan: SubscriptionPlan {
        guard isActive else { return .free }

        return .subscription(
            period: SubscriptionPeriod(productIdentifier: productIdentifier),
            nextRenewalDate: expirationDate,
            willRenew: willRenew
        )
    }

}
