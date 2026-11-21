//
//  PurchaseOfferingPreview.swift
//  LocalPackage
//

#if DEBUG

public extension PurchasePackage {

    static let monthlyForPreview = PurchasePackage(
        id: "$rc_monthly",
        productIdentifier: "premium_monthly",
        period: .monthly,
        localizedPrice: "¥300",
        localizedPricePerMonth: nil,
        introductoryOffer: nil
    )

    static let yearlyForPreview = PurchasePackage(
        id: "$rc_annual",
        productIdentifier: "premium_yearly",
        period: .yearly,
        localizedPrice: "¥3,000",
        localizedPricePerMonth: "¥250",
        introductoryOffer: nil
    )

    /// 1週間の無料トライアルが使える月額プラン
    static let monthlyWithTrialForPreview = PurchasePackage(
        id: "$rc_monthly",
        productIdentifier: "premium_monthly",
        period: .monthly,
        localizedPrice: "¥300",
        localizedPricePerMonth: nil,
        introductoryOffer: .init(
            paymentMode: .freeTrial,
            period: .init(value: 1, unit: .week),
            numberOfPeriods: 1,
            localizedPrice: "¥0"
        )
    )

}

public extension PurchaseOffering {

    /// 月額と年額を並べたプランの一覧
    static let previewValue = PurchaseOffering(packages: [.monthlyForPreview, .yearlyForPreview])

}

#endif
