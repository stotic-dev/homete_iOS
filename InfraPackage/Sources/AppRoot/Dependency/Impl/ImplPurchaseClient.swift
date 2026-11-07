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
        appUserId: {
            Purchases.isConfigured ? Purchases.shared.appUserID : nil
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
        },
        restorePurchases: {
            let customerInfo = try await Purchases.shared.restorePurchases()
            return makeEntitlementInfo(from: customerInfo)
        },
        fetchOffering: {
            // 初期化前にPurchases.sharedへ触れるとSDKの中でクラッシュする
            guard Purchases.isConfigured else { throw PurchaseError.notConfigured }
            guard let offering = try await Purchases.shared.offerings().current else {
                throw PurchaseError.offeringNotFound
            }
            var packages: [PurchasePackage] = []
            for package in offering.availablePackages {
                await packages.append(makePurchasePackage(from: package))
            }
            return PurchaseOffering(packages: packages)
        },
        purchase: { packageId in
            guard Purchases.isConfigured else { throw PurchaseError.notConfigured }
            // SDKはOfferingsをキャッシュしているため、取り直しても通信は増えない
            guard let package = try await Purchases.shared.offerings().current?.package(identifier: packageId) else {
                throw PurchaseError.packageNotFound
            }
            do {
                let result = try await Purchases.shared.purchase(package: package)
                guard !result.userCancelled else { return .cancelled }
                return .purchased(makeEntitlementInfo(from: result.customerInfo))
            } catch let error as ErrorCode where error == .paymentPendingError {
                return .pending
            }
        }
    )

}

/// 月額より長い期間のプランだけ、1か月あたりの価格を持たせる
private func makePurchasePackage(from package: Package) async -> PurchasePackage {
    let product = package.storeProduct
    let period = makeSubscriptionPeriod(from: product)
    return await PurchasePackage(
        id: package.identifier,
        productIdentifier: product.productIdentifier,
        period: period,
        localizedPrice: product.localizedPriceString,
        localizedPricePerMonth: period == .yearly ? product.localizedPricePerMonth : nil,
        introductoryOffer: makeIntroductoryOffer(from: product)
    )
}

private func makeSubscriptionPeriod(from product: StoreProduct) -> HometeDomain.SubscriptionPeriod {
    switch product.subscriptionPeriod?.unit {
    case .month where product.subscriptionPeriod?.value == 1:
        .monthly

    case .year where product.subscriptionPeriod?.value == 1:
        .yearly

    default:
        HometeDomain.SubscriptionPeriod(productIdentifier: product.productIdentifier)
    }
}

/// 利用資格がある場合だけ導入オファーを返す
/// - Note: 資格を確かめられなかった（`unknown`）ときも出さない。使えないオファーを訴求しないため
private func makeIntroductoryOffer(from product: StoreProduct) async -> IntroductoryOffer? {
    guard let discount = product.introductoryDiscount else { return nil }
    let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
    guard eligibility == .eligible else { return nil }
    return IntroductoryOffer(
        paymentMode: makePaymentMode(from: discount.paymentMode),
        period: OfferPeriod(
            value: discount.subscriptionPeriod.value,
            unit: makeOfferPeriodUnit(from: discount.subscriptionPeriod.unit)
        ),
        numberOfPeriods: discount.numberOfPeriods,
        localizedPrice: discount.localizedPriceString
    )
}

private func makePaymentMode(from mode: StoreProductDiscount.PaymentMode) -> IntroductoryOffer.PaymentMode {
    switch mode {
    case .freeTrial:
        .freeTrial

    case .payAsYouGo:
        .payAsYouGo

    case .payUpFront:
        .payUpFront
    }
}

private func makeOfferPeriodUnit(from unit: RevenueCat.SubscriptionPeriod.Unit) -> OfferPeriod.Unit {
    switch unit {
    case .day:
        .day

    case .week:
        .week

    case .month:
        .month

    case .year:
        .year
    }
}

private let premiumEntitlementId = "taichi sato Pro"

private func makeEntitlementInfo(from customerInfo: CustomerInfo) -> HometeDomain.EntitlementInfo {
    let entitlement = customerInfo.entitlements[premiumEntitlementId]
    return HometeDomain.EntitlementInfo(
        isActive: entitlement?.isActive == true,
        productIdentifier: entitlement?.productIdentifier ?? "",
        expirationDate: entitlement?.expirationDate,
        willRenew: entitlement?.willRenew == true
    )
}
#endif
