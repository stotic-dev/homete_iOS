//
//  PurchaseOffering.swift
//  LocalPackage
//

/// Paywallに並べるプランの一覧
public struct PurchaseOffering: Equatable, Sendable {

    public let packages: [PurchasePackage]

    public init(packages: [PurchasePackage]) {
        self.packages = packages
    }

}

/// 購入できるプラン1つ分
public struct PurchasePackage: Equatable, Sendable, Identifiable {

    /// 購入するときに指定するID（RevenueCatのPackageの識別子）
    public let id: String
    /// App Store Connect上のプロダクトID。契約中のプランとの突き合わせに使う
    public let productIdentifier: String
    public let period: SubscriptionPeriod
    /// 課金期間あたりの価格（例: 「¥3,000」）
    public let localizedPrice: String
    /// 1か月あたりの価格。月額より長い期間のプランだけ持つ
    public let localizedPricePerMonth: String?
    /// 導入オファー。オファーが無い、または利用資格が無ければnil
    public let introductoryOffer: IntroductoryOffer?

    public init(
        id: String,
        productIdentifier: String,
        period: SubscriptionPeriod,
        localizedPrice: String,
        localizedPricePerMonth: String?,
        introductoryOffer: IntroductoryOffer?
    ) {
        self.id = id
        self.productIdentifier = productIdentifier
        self.period = period
        self.localizedPrice = localizedPrice
        self.localizedPricePerMonth = localizedPricePerMonth
        self.introductoryOffer = introductoryOffer
    }

}

/// 無料トライアルなどの導入オファー
public struct IntroductoryOffer: Equatable, Sendable {

    public let paymentMode: PaymentMode
    /// 1回分の期間
    public let period: OfferPeriod
    /// `period`を何回くり返すか
    public let numberOfPeriods: Int
    /// 1回分の価格。無料トライアルなら0円の表示
    public let localizedPrice: String

    public init(paymentMode: PaymentMode, period: OfferPeriod, numberOfPeriods: Int, localizedPrice: String) {
        self.paymentMode = paymentMode
        self.period = period
        self.numberOfPeriods = numberOfPeriods
        self.localizedPrice = localizedPrice
    }

}

public extension IntroductoryOffer {

    enum PaymentMode: Equatable, Sendable {

        /// 無料トライアル
        case freeTrial
        /// 期間ごとに割引価格を払う
        case payAsYouGo
        /// 割引価格を最初にまとめて払う
        case payUpFront

    }

}

/// 導入オファーの期間（例: 1週間、3か月）
public struct OfferPeriod: Equatable, Sendable {

    public let value: Int
    public let unit: Unit

    public init(value: Int, unit: Unit) {
        self.value = value
        self.unit = unit
    }

}

public extension OfferPeriod {

    enum Unit: Equatable, Sendable {

        case day
        case week
        case month
        case year

    }

}
