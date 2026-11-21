//
//  PurchaseClient.swift
//  LocalPackage
//

public struct PurchaseClient: Sendable {

    public let logIn: @Sendable (String) async throws -> Void
    public let logOut: @Sendable () async throws -> Void
    /// 今の購入者のApp User ID。SDKを初期化していなければnil
    /// - Note: `logIn`に失敗していると、アカウントのIDではなく匿名のID（`$RCAnonymousID:...`）になる
    public let appUserId: @Sendable () -> String?
    public let fetchEntitlementInfo: @Sendable () async throws -> EntitlementInfo
    public let entitlementInfoUpdates: @Sendable () -> AsyncStream<EntitlementInfo>
    public let showManageSubscriptions: @Sendable () async throws -> Void
    /// 過去の購入を復元し、復元後のエンタイトルメント状態を返す
    public let restorePurchases: @Sendable () async throws -> EntitlementInfo
    /// Paywallに並べるプランの一覧。導入オファーは利用資格がある場合だけ入れる
    public let fetchOffering: @Sendable () async throws -> PurchaseOffering
    /// 指定したプラン（`PurchasePackage.id`）を購入する
    public let purchase: @Sendable (_ packageId: String) async throws -> PurchaseResult

    public init(
        logIn: @Sendable @escaping (String) async throws -> Void = { _ in },
        logOut: @Sendable @escaping () async throws -> Void = {},
        appUserId: @Sendable @escaping () -> String? = { nil },
        fetchEntitlementInfo: @Sendable @escaping () async throws -> EntitlementInfo = {
            .init(isActive: false, productIdentifier: "", expirationDate: nil, willRenew: false)
        },
        entitlementInfoUpdates: @Sendable @escaping () -> AsyncStream<EntitlementInfo> = { AsyncStream { _ in } },
        showManageSubscriptions: @Sendable @escaping () async throws -> Void = {},
        restorePurchases: @Sendable @escaping () async throws -> EntitlementInfo = {
            .init(isActive: false, productIdentifier: "", expirationDate: nil, willRenew: false)
        },
        fetchOffering: @Sendable @escaping () async throws -> PurchaseOffering = { .init(packages: []) },
        purchase: @Sendable @escaping (_ packageId: String) async throws -> PurchaseResult = { _ in .cancelled }
    ) {
        self.logIn = logIn
        self.logOut = logOut
        self.appUserId = appUserId
        self.fetchEntitlementInfo = fetchEntitlementInfo
        self.entitlementInfoUpdates = entitlementInfoUpdates
        self.showManageSubscriptions = showManageSubscriptions
        self.restorePurchases = restorePurchases
        self.fetchOffering = fetchOffering
        self.purchase = purchase
    }

}

public extension PurchaseClient {

    static let previewValue = PurchaseClient()

}
